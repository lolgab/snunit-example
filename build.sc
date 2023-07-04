import mill._
import mill.scalalib._
import mill.scalanativelib._
import mill.util.Jvm

object root extends RootModule with ScalaNativeModule {
  def scalaVersion = "3.3.0"
  def scalaNativeVersion = "0.4.14"

  def ivyDeps = super.ivyDeps() ++ Agg(
    ivy"com.github.lolgab::snunit-http4s0.23::0.7.1",
    ivy"org.http4s::http4s-dsl::0.23.19"
  )

  def unitConf = T.source { T.workspace / "conf.json" }

  def runUnit() = T.command {
    val wd = T.workspace
    val statedir = T.dest / "statedir"
    os.makeDir.all(statedir)
    os.copy.into(unitConf().path, statedir)
    os.copy.into(nativeLink(), T.dest)

    Jvm.runSubprocess(
      commandArgs = Seq(
        "unitd",
        "--statedir",
        "statedir",
        "--log",
        "/dev/stdout",
        "--no-daemon",
        "--control",
        "127.0.0.1:9000"
      ),
      envArgs = Map(),
      workingDir = T.dest
    )
  }
}
