export default {
  resource: "admin.adminPlugins.show",

  path: "/plugins",

  map() {
    this.route("discourse-ai-moderator-logs", { path: "logs" });
  },
};
