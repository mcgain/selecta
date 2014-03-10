require_relative "spec_helper"

describe "score" do
  def score(choice, query)
    Score.score(choice, query)
  end

  describe "basic matching" do
    it "scores infinity when the choice is empty" do
      expect(score("", "a")).to eq Float::INFINITY
    end

    it "scores 0 when the query is empty" do
      expect(score("a", "")).to eq 0.0
    end

    it "scores infinity when the query is longer than the choice" do
      expect(score("short", "longer")).to eq Float::INFINITY
    end

    it "scores infinity when the query doesn't match at all" do
      expect(score("a", "b")).to eq Float::INFINITY
    end

    it "scores infinity when only a prefix of the query matches" do
      expect(score("ab", "ac")).to eq Float::INFINITY
    end

    it "scores less than infinity when it matches" do
      expect(score("a", "a")).to be < Float::INFINITY
      expect(score("ab", "a")).to be < Float::INFINITY
      expect(score("ba", "a")).to be < Float::INFINITY
      expect(score("bab", "a")).to be < Float::INFINITY
      expect(score("babababab", "aaaa")).to be < Float::INFINITY
    end

    it "scores the length of the query when the query is a substring" do
      expect(score("xa", "a")).to eq "a".length
      expect(score("xab", "ab")).to eq "ab".length
      expect(score("xalongstring", "alongstring")).to eq "alongstring".length
      expect(score("lib/search.rb", "earc")).to eq "earc".length
    end
  end

  describe "character matching" do
    it "matches punctuation" do
      expect(score("/! symbols $^", "/!$^")).to be < Float::INFINITY
    end

    it "is case insensitive" do
      x = score("a", "a")
      y = score("a", "A")
      z = score("A", "a")
      w = score("A", "A")
      expect(x).to eq y
      expect(y).to eq z
      expect(z).to eq w
    end

    it "doesn't match when the same letter is repeated in the choice" do
      expect(score("a", "aa")).to eq Float::INFINITY
    end
  end

  describe "match quality" do
    it "scores higher for tighter matches" do
      expect(score("reason", "eas")).to eq "eas".length
      expect(score("beagles", "eas")).to eq "eagles".length

      expect(score("README", "em")).to eq "EADM".length
      expect(score("benchmark", "em")).to eq "enchm".length
    end

    it "sometimes scores longer strings higher if they have a tighter match" do
      expect(score("xlong12long", "12")).to eq "12".length
      expect(score("x1long2", "12")).to eq "1long2".length
    end

    it "scores the tighter of two matches, regardless of order" do
      tight = "a12"
      loose = "a1b2"
      expect(score(tight + loose, "12")).to eq "12".length
      expect(score(loose + tight, "12")).to eq "12".length
    end

    describe "at word boundaries" do
      it "doesn't score characters before a match at a word boundary" do
        # A character at a boundary counts as only one character toward the
        # score. Because the "b" in "foo-x-bar" is at a word boundary, the
        # "-x-b" contributes only 1 point toward the score, not 4.
        expect(score("fooxbar", "foobar")).to eq 7
        expect(score("foo-x-bar", "foobar")).to eq 6
      end

      it "finds optimal non-boundary matches when boundary matches are present" do
        # The "xayz" matches in both cases because it's shorter than
        # "xaa-yaaz", even considering the latter's boundary bonus.
        expect(score("xayz/xaa-yaaz", "xyz")).to eq 4
        expect(score("xaa-yaaz/xayz", "xyz")).to eq 4
      end

      it "finds optimal boundary matches when non-boundary matches are present" do
        expect(score("xa-yaz/xaaaayz", "xyz")).to eq 4
        expect(score("xaaaayz/xa-yaz", "xyz")).to eq 4
      end
    end
  end
end
