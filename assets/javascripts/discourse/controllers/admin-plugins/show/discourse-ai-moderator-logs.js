import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class extends Controller {
  @tracked logs = [];
  @tracked stats = null;
  @tracked enabled = false;
  @tracked onUncertain = "hold";
  @tracked loading = false;
  @tracked toggling = false;

  @action
  async loadLogs() {
    this.loading = true;
    try {
      const data = await ajax(
        "/admin/plugins/discourse-ai-moderator/logs.json"
      );
      this.logs = data.logs || [];
      this.stats = data.stats;
      this.enabled = data.enabled;
      this.onUncertain = data.on_uncertain;
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loading = false;
    }
  }

  @action
  async toggleEnabled() {
    if (this.toggling) {
      return;
    }
    this.toggling = true;
    const next = !this.enabled;
    try {
      await ajax("/admin/site_settings/ai_moderator_enabled", {
        type: "PUT",
        data: { ai_moderator_enabled: next },
      });
      this.enabled = next;
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.toggling = false;
    }
  }
}
