module JamRuby
  module NativeView
    def post_delayed len, &b
      postDelayed b, len
    end
  end
end
