import { withPluginApi } from "discourse/lib/plugin-api";

const PLUGIN_ID = "discourse-ai-moderator";

export default {
  name: "discourse-ai-moderator-admin-plugin-configuration-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.setAdminPluginIcon(PLUGIN_ID, "shield-halved");
      api.addAdminPluginConfigurationNav(PLUGIN_ID, [
        {
          label: "ai_moderator.admin.logs.nav_title",
          route: "adminPlugins.show.discourse-ai-moderator-logs",
        },
      ]);
    });
  },
};
