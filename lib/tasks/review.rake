desc "Review done by Static Analysis Tools"
task :review do |variable|
  `flay app > reports/flay_app.out`
  `excellent app lib -o reports/excellent.html`
  `brakeman . -o reports/brakeman.html`
  `rubocop app -f o -o reports/rubocop_summary.out`
  `rubocop app -f s -o reports/rubocop.out`
  `rails_best_practices -f html --output-file reports/rails_best_practices.html`
  `yard stats --list-undoc > reports/yard.out`
end