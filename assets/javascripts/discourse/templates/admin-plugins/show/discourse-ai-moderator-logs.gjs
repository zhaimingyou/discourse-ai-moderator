import DBreadcrumbsItem from "discourse/ui-kit/d-breadcrumbs-item";
import DButton from "discourse/ui-kit/d-button";
import DConditionalLoadingSpinner from "discourse/ui-kit/d-conditional-loading-spinner";
import DPageSubheader from "discourse/ui-kit/d-page-subheader";
import { i18n } from "discourse-i18n";

export default <template>
  <DBreadcrumbsItem
    @path="/admin/plugins/discourse-ai-moderator/logs"
    @label={{i18n "ai_moderator.admin.logs.nav_title"}}
  />

  <div class="ai-moderator-admin admin-detail">
    <DPageSubheader
      @titleLabel={{i18n "ai_moderator.admin.logs.title"}}
      @descriptionLabel={{i18n "ai_moderator.admin.logs.description"}}
    />

    <div class="ai-moderator-toolbar">
      <div class="ai-moderator-status">
        {{#if @controller.enabled}}
          <span class="ai-moderator-badge -on">{{i18n
              "ai_moderator.admin.status_on"
            }}</span>
        {{else}}
          <span class="ai-moderator-badge -off">{{i18n
              "ai_moderator.admin.status_off"
            }}</span>
        {{/if}}
        <span class="ai-moderator-uncertain">{{i18n
            "ai_moderator.admin.uncertain_policy"
          }}: {{@controller.onUncertain}}</span>
      </div>

      <div class="ai-moderator-actions">
        <DButton
          @action={{@controller.toggleEnabled}}
          @disabled={{@controller.toggling}}
          @icon={{if @controller.enabled "toggle-on" "toggle-off"}}
          @label={{if
            @controller.enabled
            "ai_moderator.admin.disable"
            "ai_moderator.admin.enable"
          }}
          class={{if @controller.enabled "btn-danger" "btn-primary"}}
        />
        <DButton
          @action={{@controller.loadLogs}}
          @icon="arrows-rotate"
          @label="ai_moderator.admin.refresh"
          class="btn-default"
        />
      </div>
    </div>

    {{#if @controller.stats}}
      <div class="ai-moderator-stats">
        <span class="ai-moderator-stat -approve">{{i18n
            "ai_moderator.admin.stats.approve"
          }}: {{@controller.stats.approve}}</span>
        <span class="ai-moderator-stat -reject">{{i18n
            "ai_moderator.admin.stats.reject"
          }}: {{@controller.stats.reject}}</span>
        <span class="ai-moderator-stat -hold">{{i18n
            "ai_moderator.admin.stats.hold"
          }}: {{@controller.stats.hold}}</span>
        <span class="ai-moderator-stat -error">{{i18n
            "ai_moderator.admin.stats.error"
          }}: {{@controller.stats.error}}</span>
        <span class="ai-moderator-stat -total">{{i18n
            "ai_moderator.admin.stats.total"
          }}: {{@controller.stats.total}}</span>
      </div>
    {{/if}}

    <DConditionalLoadingSpinner @condition={{@controller.loading}}>
      {{#if @controller.logs.length}}
        <table class="ai-moderator-logs-table">
          <thead>
            <tr>
              <th>{{i18n "ai_moderator.admin.table.time"}}</th>
              <th>{{i18n "ai_moderator.admin.table.decision"}}</th>
              <th>{{i18n "ai_moderator.admin.table.user"}}</th>
              <th>{{i18n "ai_moderator.admin.table.title"}}</th>
              <th>{{i18n "ai_moderator.admin.table.reason"}}</th>
            </tr>
          </thead>
          <tbody>
            {{#each @controller.logs as |log|}}
              <tr class="ai-moderator-log-row -{{log.decision}}">
                <td class="ai-moderator-time">{{log.created_at}}</td>
                <td>
                  <span
                    class="ai-moderator-decision -{{log.decision}}"
                  >{{log.decision}}</span>
                </td>
                <td>{{log.username}}</td>
                <td class="ai-moderator-title">{{log.title}}</td>
                <td class="ai-moderator-reason">{{log.reason}}</td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      {{else}}
        <p class="ai-moderator-empty">{{i18n "ai_moderator.admin.empty"}}</p>
      {{/if}}
    </DConditionalLoadingSpinner>
  </div>
</template>
