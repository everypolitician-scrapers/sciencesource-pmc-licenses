#!/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open-uri/cached'
require 'pry'
require 'rest-client'
require 'scraped'
require 'scraperwiki'

class String
  def quoted
    '"%s"' % self
  end
end

WIKIDATA_SPARQL_URL = 'https://query.wikidata.org/sparql?format=json&query=%s'

def sparql_url(query)
  WIKIDATA_SPARQL_URL % CGI.escape(query)
end

class ArticleResults < Scraped::JSON
  field :items do
    json[:results][:bindings].map { |result| fragment(result => Article) }
  end

  class Article < Scraped::JSON
    field :id do
      json.dig(:item, :value).to_s.split('/').last
    end

    field :title do
      json.dig(:itemLabel, :value)
    end

    field :url do
      json.dig(:url, :value).to_s
    end
  end
end

class CCLicense < Scraped::JSON
  field :ids do
    json[:results][:bindings].map { |result| fragment(result => Row) }.map(&:itemid)
  end

  class Row < Scraped::JSON
    field :itemid do
      json.dig(:item, :value).to_s.split('/').last
    end
  end
end

class NIHArticle < Scraped::HTML
  field :license do
    noko.css('a/@href').map(&:text).find { |href| href.include? 'creativecommons.org/licenses/' }
  end
end

# Items on the ScienceSource focus list without a known license
missing_license_query = <<SPARQL
  SELECT ?item ?itemLabel ?url WHERE {
    ?item wdt:P31 wd:Q13442814; wdt:P5008 wd:Q55439927 ; wdt:P932 ?pmcid.
    MINUS { ?item wdt:P275 [] }
    wd:P932 wdt:P1630 ?formatterurl .
    BIND(IRI(REPLACE(?pmcid, '^(.+)$', ?formatterurl)) AS ?url).
    SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
  }
SPARQL

# Wikidata item for the CC License, by URL
license_lookup = 'SELECT ?item WHERE { ?item wdt:P856 <%s> }'

Scraped::Scraper.new(sparql_url(missing_license_query) => ArticleResults).scraper.items.each do |article|
  next unless article.url.include? 'nih.gov'

  raw_license = NIHArticle.new(response: Scraped::Request.new(url: article.url).response).license or next
  license = raw_license.sub('http:', 'https:').gsub(%r{(?<!\/)$}, '/')
  lscraper = Scraped::Scraper.new(sparql_url(license_lookup % license) => CCLicense).scraper

  license_wdid = lscraper.ids
  if license_wdid.count == 1
    puts [article.id, 'P275', license_wdid, 'S854', article.url.quoted].join("\t")
  else
    warn "Can't find unique Wikidata item for #{license}"
  end
end
