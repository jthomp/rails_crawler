## [Unreleased]

- Development setup works on Ruby 4.0: the unused `vcr` development dependency is removed
  (vcr 6.3.1 fails to load on Ruby 4.0, which no longer ships `CGI.parse`), and the locked
  nokogiri is updated to 1.19.7, which has precompiled gems for Ruby 3.2 through 4.0.
- CI runs the specs on Ruby 3.4 and 4.0 as well as 3.2 and 3.3.

## [0.4.1] - 2026-11-05

- Fix every request failing when the base URL has no scheme (`BASE_URL=www.example.com`).
  Such a URL now gets `https://`, or `http://` for a loopback host such as `localhost:3000`.
- A base URL that is not http(s), or has no host, is rejected up front with a clear error
  rather than reported as a failure on every page.

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
