package controllers

import play.api._
import play.api.mvc._
import play.api.libs.json._

object Application extends Controller {
  
  def index = Action {
    Ok(views.html.index("Your new application is ready."))
  }
  
  // This is the action that GitLab will hit
  def commitHook = Action(parse.json) { request =>
  	Ok("asdf")
  }
}