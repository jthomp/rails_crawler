# frozen_string_literal: true

module RailsCrawler
  # One kind of model-backed page on the site: which records have a page of
  # their own and how to build each one's path. The full crawl seeds its queue
  # from these, and `rake crawler:crawl_models` requests every one.
  #
  # A check whose model or route helper the app does not define is skipped, so
  # the defaults can name every model the gem knows about without each app
  # having all of them.
  class ModelCheck
    attr_reader :model_name, :route_names, :param, :scope

    # Articles can be switched off site-wide (Siteparam#articles_enabled?);
    # while they are, the storefront 404s every article and tag page, so there
    # is nothing to check.
    ARTICLES_ENABLED = lambda do
      next true unless Object.const_defined?(:Siteparam)

      siteparam = Object.const_get(:Siteparam).first
      next true unless siteparam.respond_to?(:articles_enabled?)

      siteparam.articles_enabled? || false
    end

    # model_name:: the model's class name, as a string ("Product").
    # routes::     route helper name(s) to try in order; the first one the app
    #              defines is used (e.g. %i[page_page_path static_page_path]).
    # param::      the record attribute passed to the helper (default :permalink).
    # scope::      which records have a page: a class-method name (:visible), a
    #              callable returning the records, or nil for every record.
    # enabled::    optional callable; the check is skipped while it returns
    #              false (a site-wide feature gate, say).
    def initialize(model_name, routes:, param: :permalink, scope: nil, enabled: nil)
      @model_name = model_name.to_s
      @route_names = Array(routes).map(&:to_sym)
      @param = param.to_sym
      @scope = scope
      @enabled = enabled
    end

    # How the check is named in output.
    def label
      @model_name
    end

    # The page types the gem knows about. Each is skipped in an app that lacks
    # its model or route, so the list is safe to use as-is.
    def self.defaults
      [
        new("Product",    routes: :product_page_path,  scope: :visible),
        new("Category",   routes: :category_page_path, scope: :visible),
        new("Page",       routes: %i[page_page_path static_page_path], scope: :visible),
        new("Article",    routes: :article_page_path, scope: :published, enabled: ARTICLES_ENABLED),
        new("ArticleTag", routes: :article_tag_path,  scope: :with_published_articles, enabled: ARTICLES_ENABLED),
        new("Faq",        routes: :faq_path,          scope: :visible, param: :id),
        new("Zone",       routes: :zone_page_path,    param: :number)
      ]
    end

    def self.url_helpers
      Rails.application.routes.url_helpers
    end

    def model
      Object.const_get(@model_name) if Object.const_defined?(@model_name)
    end

    # The first of route_names the app defines, or nil.
    def route_name
      helpers = self.class.url_helpers
      @route_names.find { |name| helpers.respond_to?(name) }
    end

    def enabled?
      return true if @enabled.nil?

      @enabled.call || false
    end

    # Why this check will be skipped, or nil when it can run.
    def skip_reason
      return "#{@model_name} is not defined" unless model
      return "no route helper named #{@route_names.join(" or ")}" unless route_name
      return "disabled" unless enabled?

      nil
    end

    def available?
      skip_reason.nil?
    end

    # The records that have a page.
    def records
      case @scope
      when nil then model.respond_to?(:all) ? model.all : model
      when Symbol, String then model.public_send(@scope)
      else @scope.call
      end
    end

    def each_record(&block)
      found = records
      found.respond_to?(:find_each) ? found.find_each(&block) : found.each(&block)
    end

    def path_for(record)
      self.class.url_helpers.public_send(route_name, record.public_send(@param))
    end

    # Yields each record with its path.
    def each_page
      each_record { |record| yield record, path_for(record) }
    end

    # Every page's full URL under base_url.
    def urls(base_url)
      base = base_url.chomp("/")
      found = []
      each_page { |_record, path| found << "#{base}#{path}" }
      found
    end
  end
end
