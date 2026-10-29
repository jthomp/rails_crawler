## [Unreleased]

## [0.4.0] - 2026-10-29

- Add support for Page, Article, ArticleTag, Faq and Zone pages, alongside Product and Category.
- Model-backed page types are now configurable: `config.model_checks` holds a list of
  `RailsCrawler::ModelCheck`s (model, route helper, param, scope, feature gate), and
  `config.static_paths` adds fixed paths such as listing pages. Both `crawler:crawl_models`
  and the full crawl's seed URLs use them.
- Only records the storefront shows are checked (`visible`, `published`), so hidden
  records no longer show up as 404s.
- `crawler:crawl_models` honours the configured user agent, timeout and delay, and
  supports `FORMAT` and `OUTPUT_FILE` like `crawler:crawl`.

## [0.3.4] - 2026-05-12

- Update nokogiri to 1.18.3

## [0.2.8] - 2025-07-23

- Initial release
- Add support for Product, Category and (Static)Pages.
