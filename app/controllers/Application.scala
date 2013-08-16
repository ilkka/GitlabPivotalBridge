package controllers

import play.api._
import play.api.mvc._
import play.api.libs.json._
import play.api.libs.ws.{Response => WsResponse, WS => WS}
import play.api.libs.concurrent.Execution.Implicits._

import scala.concurrent.Future

object Application extends Controller {
    def index = Action {
        Ok(views.html.index("See README file."))
    }

    case class Author(name: String, email: String)
    case class Commit(id: String, message: String, timestamp: String, url: String, author: Author)
    implicit val authorReads = Json.reads[Author]
    implicit val commitReads = Json.reads[Commit]

    // This is the action that GitLab will hit
    def commitHook = Action(parse.json) { request =>
        val commits = (request.body \ "commits").as[List[Commit]]
        commits.foreach(c => {
            Logger.debug(s"Handling message ${c.message}")
            val result: Future[WsResponse] = {
                val trackerMsg = s"<source_commit><message>${c.message}</message><author>${c.author.email}</author><commit_id>${c.id}</commit_id><url>${c.url}</url></source_commit>"
                Logger.debug(s"Sending to tracker: ${trackerMsg}")
                WS.url("http://www.pivotaltracker.com/services/v3/source_commits")
                    .withHeaders(
                        CONTENT_TYPE -> "application/xml",
                        "X-TrackerToken" -> Play.current.configuration.getString("pivotal.token").getOrElse("")
                    )
                    .post(trackerMsg)
            }
            result onSuccess {
                case response => Logger.debug(s"${c.id} => ${response.body}")
            }
        })
        Ok("")
    }
}