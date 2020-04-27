# klaviyo-utils
Utilities for working with Klaviyo

By using this software, you've agreed to the license in the included [LICENSE](LICENSE) file. Per the license, this softeare is provided "as is", without warranty of any kind.

## Usage of Flush for the non-Rubyist Mac user
Open the Terminal app and type the following commands:
```
gem install bundler
git clone https://github.com/welearnednothing/klaviyo-utils.git
cd klaviyo-utils
bundle
```

To use the script, you'll need three things:
- your Klaviyo API key
- the list ID that you'd like to delete users from
- a CSV where the first column is the email addresses you'd like to remove. All other columns will be ignored, as well as headers. Put the CSV file in the same directory as this file, and we're ready to go!

Now type:
```
ruby flush.rb
```
cross your fingers, hit \<Enter\>, and follow the prompts!
