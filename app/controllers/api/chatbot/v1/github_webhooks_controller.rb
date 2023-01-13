# frozen_string_literal: true

module Api
  module Chatbot
    module V1
      class GithubWebhooksController < ActionController::Base
        skip_forgery_protection
        include GithubWebhook::Processor

        @@Tokens = nil
        @@call_count = 0

        def initialize
          puts 'initialize GithubWebhooks controller'
          get_tokens
        end

        def get_tokens
          puts 'Getting token list..'
          @@Tokens = TomTokensQueue.where(source: 'github')
        end

        def getNextToken
          @@call_count += 1
          next_token_index = (@@call_count % @@Tokens.length)
          @@Tokens[next_token_index].token
        end

        # Handle issue comment event
        def github_issue_comment(payload)
          return unless payload['action'] == 'created'
          return unless payload['comment']['body'].include? '@0capa-beta'

          project = TomProject.where(repoid: payload['repository']['id']).first

          case payload['comment']['body']
          when /switch/
            case payload['comment']['body']
            when /Random/
              puts 'скорее всего нас попросили свитчнуться в рандом мод'
              project.mode = 'Random'
              project.save
              HTTP[accept: 'application/vnd.github.v3+json', Authorization: "token #{getNextToken}"].post(
                payload['issue']['comments_url'], json: { body: 'Changing mode for project to "Random"' }
              )
            when /ML/
              puts 'скорее всего нас попросили свитчнуться в мл мод'
              project.mode = 'ML'
              project.save
              HTTP[accept: 'application/vnd.github.v3+json', Authorization: "token #{getNextToken}"].post(
                payload['issue']['comments_url'], json: { body: 'Changing mode for project to "ML"' }
              )
            end
          when /hello/
            HTTP[accept: 'application/vnd.github.v3+json', Authorization: "token #{getNextToken}"].post(
              payload['issue']['comments_url'], json: { body: "Hello! Good news: everything works fine.\n0capa-beta detailed info:\nNew suggestions every 12hours.\nCurrent mode for project is '#{project.mode}'" }
            )

          when /status/
            HTTP[accept: 'application/vnd.github.v3+json', Authorization: "token #{getNextToken}"].post(
              payload['issue']['comments_url'], json: { body: 'Hello! Good news: everything works fine.' }
            )
          when /export/
            export_query = { url: project.repo_url }.to_query
            export_url = "https://0capa.ru/api/export/v1/repo_stats?#{export_query}"

            HTTP[accept: 'application/vnd.github.v3+json', Authorization: "token #{getNextToken}"].post(
              payload['issue']['comments_url'], json: { body: "[Click](#{export_url}) to download your stats" }
            )
          when /stop/
            TomProject.where(repoid: payload['repository']['id']).destroy_all
            HTTP[accept: 'application/vnd.github.v3+json', Authorization: "token #{getNextToken}"].post(
              payload['issue']['comments_url'], json: { body: 'Hello! Ima so sorry you dont want to be friends with me anymore!!!!! ![](https://i.imgur.com/hjnZvs5.png)' }
            )
          end
        end

        private

        def webhook_secret(_payload)
          'GITHUB_WEBHOOK_SECRET'
        end
      end
    end
  end
end
