using BinDeps
using Compat

@BinDeps.setup

mecab = library_dependency("libmecab")

const version = "0.996"

provides(Sources,
         URI("https://mecab.googlecode.com/files/mecab-$(version).tar.gz"),
         mecab,
         unpacked_dir="mecab-$(version)")

prefix = joinpath(BinDeps.depsdir(mecab), "usr")
srcdir = joinpath(BinDeps.depsdir(mecab), "src", "mecab-$(version)")

provides(SimpleBuild,
          (@build_steps begin
              GetSources(mecab)
              @build_steps begin
                  ChangeDirectory(srcdir)
                  `./configure --prefix=$prefix --enable-utf8-only`
                  `make`
                  `make install`
              end
           end), mecab, os = :Unix)

@BinDeps.install @compat Dict(:libmecab => :libmecab)

# mecab-ipadic install

function install_ipadic()
    const ipadic_version = "2.7.0-20070801"
    mecabconfig = joinpath(BinDeps.depsdir(mecab), "usr", "bin", "mecab-config")

    # download
    url = "https://drive.google.com/uc?export=download&id=0B4y35FiV1wh7MWVlSDBCSXZMTXM"
    cd(BinDeps.downloadsdir(mecab))
    filename = "mecab-ipadic-$(ipadic_version).tar.gz"
    if !isfile(joinpath(BinDeps.downloadsdir(mecab), filename))
        run(download_cmd(url, filename))
    end

    # unpack
    unpack_dir = "mecab-ipadic-$(ipadic_version)"
    if !isdir(unpack_dir)
        run(`tar xzvf $(filename)`)
    end
    cd("$(unpack_dir)")

    # make & install
    run(`./configure --prefix=$prefix --with-charset=utf8 --with-mecab-config=$(mecabconfig)`)
    run(`make`)
    run(`make install`)
end

ipadic_dir = joinpath(BinDeps.depsdir(mecab), "usr", "lib", "mecab", "dic", "ipadic")
if isempty(Libdl.find_library(["libmecab"])) && !isdir(ipadic_dir)
    @unix_only install_ipadic()
end
