import coursier.maven.MavenRepository
import mill._
import mill.scalalib._
import mill.scalanativelib._
import mill.util.Jvm

trait Base extends ScalaModule {
  def scalaVersion = "3.3.1"
}

object root extends RootModule with Base with ScalaNativeModule {
  def scalaNativeVersion = "0.4.15"

  val http4sVersion = "0.23.23-63-4d9afaa-SNAPSHOT"

  def repositoriesTask = T.task {
    super.repositoriesTask() ++ Seq(
      MavenRepository(
        "https://s01.oss.sonatype.org/content/repositories/snapshots"
      )
    )
  }

  def ivyDeps = super.ivyDeps() ++ Agg(
    ivy"com.github.lolgab::snunit-http4s0.23::0.7.1",
    ivy"org.typelevel::cats-core::2.11-85633a2-20230918T165946Z-SNAPSHOT",
    ivy"org.http4s::http4s-core::$http4sVersion",
    ivy"org.http4s::http4s-dsl::$http4sVersion"
  )

  def unitConf = T.source { T.workspace / "conf.json" }

  def runUnit() = T.command {
    val wd = T.workspace
    val statedir = T.dest / "statedir"
    os.makeDir.all(statedir)
    os.copy.into(unitConf().path, statedir)
    os.copy.into(nativeLink(), T.dest)

    `dev-server`.runBackground(
      "unitd --statedir statedir --log /dev/stdout --no-daemon --control 127.0.0.1:9000"
    )()
  }

  object `dev-server` extends Base
}
