=begin
This could just as well be a shell script ...

Create a *.jar, for jRuby, from installing gems or a bundler Gemfile

--vbatts
=end

require "gemjar/version"
require "optparse"
require "rbconfig"
require "tmpdir"
require "fileutils"

module Gemjar
  def parse_args(args)
    options = {
      :jruby => "jruby",
      :gems => [],
    }
    opts = OptionParser.new do |opts|
      opts.banner = File.basename(__FILE__) + "[-b [Gemfile]] [-g gem[,version]]..."
      opts.on("-j", "--jruby CMD", "CMD to use to call jruby (Default '#{options[:jruby]}')") do |o|
        options[:jruby] = o
      end
      opts.on("-g", "--gem GEMNAME", "GEMNAME to install. If ',<version>' is a append, it will specify that version of the gem") do |o|
        options[:gems] << o
      end
      opts.on("-b", "--bundle [GEMFILE]", "make the gemjar from a current directory Gemfile or specified") do |o|
        if o.nil? and ! FileTest.file?("Gemfile")
          raise "No Gemfile present or provided"
        end
        options[:bundle] = if o.nil?
                             File.join(Dir.pwd, "Gemfile")
                           else
                             File.expand_path(o)
                           end
      end
    end.parse!(args)
    return options
  end

  def cmd(cmd_str)
    IO.popen(cmd_str) do |f|
      loop do
        buf = f.read(10)
        break if buf.nil?
        print buf
        $stdout.flush
      end
    end
  end

  def gem_install(jruby, basedir, gemname)
    if gemname.include?(",")
      g, v = gemname.split(",",2)
      cmd("#{jruby} -S gem install -i #{basedir} #{g} -v=#{v}")
    else
      cmd("#{jruby} -S gem install -i #{basedir} #{gemname}")
    end
  end

  def make_jar(jarname, dirname)
    cmd("jar cf #{jarname} -C #{dirname} .")
  end

  def bundle_install
    cmd("bundle install --path ./vendor/bundle/")
  end

  def bundler_vendor_dir
    return ["vendor","bundle",
            RbConfig::CONFIG["ruby_install_name"],
            RbConfig::CONFIG["ruby_version"]].join("/")

  end

  def main(args)
    o = parse_args(args)
    p o

    tmpdir = Dir.mktmpdir
    begin
      cwd = Dir.pwd
      if o[:bundle]
        FileUtils.cd tmpdir
        FileUtils.cp o[:bundle], "Gemfile"
        bundle_install
        FileUtils.cd cwd
      end

      o[:gems].each do |gem|
        gem_install(o[:jruby], File.join(tmpdir, bundler_vendor_dir), gem)
      end

      jarname = File.basename(tmpdir) + ".jar"
      make_jar(jarname, File.join(tmpdir, bundler_vendor_dir))
      puts "Created #{jarname}"
    ensure
      # remove the directory.
      FileUtils.remove_entry_secure(tmpdir, true)
    end
  end
end
