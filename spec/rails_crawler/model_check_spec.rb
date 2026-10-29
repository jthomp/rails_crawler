# frozen_string_literal: true

require "spec_helper"

RSpec.describe RailsCrawler::ModelCheck do
  let(:record_class) { Struct.new(:id, :permalink, :number) }

  let(:widget_class) do
    records = [record_class.new(1, "one", 10), record_class.new(2, "two", 20), record_class.new(3, "three", 30)]

    Class.new do
      define_singleton_method(:all) { records }
      define_singleton_method(:visible) { records.first(2) }
    end
  end

  let(:url_helpers) do
    Class.new do
      def widget_path(permalink)
        "/widget/#{permalink}"
      end

      def other_widget_path(permalink)
        "/w/#{permalink}"
      end
    end.new
  end

  before do
    stub_const("Widget", widget_class)
    allow(described_class).to receive(:url_helpers).and_return(url_helpers)
  end

  describe "#skip_reason" do
    it "is nil when the model, route and gate are all in place" do
      check = described_class.new("Widget", routes: :widget_path)
      expect(check.skip_reason).to be_nil
      expect(check).to be_available
    end

    it "names a missing model" do
      check = described_class.new("Gadget", routes: :widget_path)
      expect(check.skip_reason).to eq("Gadget is not defined")
      expect(check).not_to be_available
    end

    it "names a missing route helper" do
      check = described_class.new("Widget", routes: %i[gadget_path gizmo_path])
      expect(check.skip_reason).to eq("no route helper named gadget_path or gizmo_path")
    end

    it "reports a feature gate that is off" do
      check = described_class.new("Widget", routes: :widget_path, enabled: -> { false })
      expect(check.skip_reason).to eq("disabled")
    end

    it "runs when the feature gate is on" do
      check = described_class.new("Widget", routes: :widget_path, enabled: -> { true })
      expect(check).to be_available
    end
  end

  describe "#route_name" do
    it "takes the first helper the app defines" do
      check = described_class.new("Widget", routes: %i[missing_path other_widget_path widget_path])
      expect(check.route_name).to eq(:other_widget_path)
    end
  end

  describe "#records" do
    it "defaults to every record" do
      check = described_class.new("Widget", routes: :widget_path)
      expect(check.records.map(&:id)).to eq([1, 2, 3])
    end

    it "calls a class method named by a symbol" do
      check = described_class.new("Widget", routes: :widget_path, scope: :visible)
      expect(check.records.map(&:id)).to eq([1, 2])
    end

    it "calls a lambda" do
      check = described_class.new("Widget", routes: :widget_path, scope: -> { Widget.all.last(1) })
      expect(check.records.map(&:id)).to eq([3])
    end
  end

  describe "#path_for" do
    it "passes the permalink by default" do
      check = described_class.new("Widget", routes: :widget_path)
      expect(check.path_for(Widget.all.first)).to eq("/widget/one")
    end

    it "passes the configured attribute" do
      check = described_class.new("Widget", routes: :widget_path, param: :number)
      expect(check.path_for(Widget.all.first)).to eq("/widget/10")
    end
  end

  describe "#urls" do
    it "builds every page's URL under the base URL" do
      check = described_class.new("Widget", routes: :widget_path, scope: :visible)
      expect(check.urls("http://example.com/")).to eq(["http://example.com/widget/one", "http://example.com/widget/two"])
    end
  end

  describe ".defaults" do
    it "covers every page type the gem knows about" do
      expect(described_class.defaults.map(&:model_name))
        .to eq(%w[Product Category Page Article ArticleTag Faq Zone])
    end

    it "is skipped wholesale in an app with none of those models" do
      expect(described_class.defaults.select(&:available?)).to be_empty
    end

    it "routes FAQs by id and zones by number" do
      by_name = described_class.defaults.to_h { |check| [check.model_name, check] }
      expect(by_name["Faq"].param).to eq(:id)
      expect(by_name["Zone"].param).to eq(:number)
    end
  end

  describe "ARTICLES_ENABLED" do
    it "is on when the app has no Siteparam" do
      expect(described_class::ARTICLES_ENABLED.call).to be true
    end

    it "follows Siteparam#articles_enabled?" do
      siteparam = Struct.new(:articles_enabled?)
      stub_const("Siteparam", Class.new)
      allow(Siteparam).to receive(:first).and_return(siteparam.new(false))
      expect(described_class::ARTICLES_ENABLED.call).to be false

      allow(Siteparam).to receive(:first).and_return(siteparam.new(true))
      expect(described_class::ARTICLES_ENABLED.call).to be true
    end
  end
end
