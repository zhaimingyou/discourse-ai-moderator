import DiscourseRoute from "discourse/routes/discourse";

export default class extends DiscourseRoute {
  setupController(controller) {
    super.setupController(...arguments);
    controller.loadLogs();
  }
}
