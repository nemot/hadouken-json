![alt text](https://github.com/nemot/hadouken-json/blob/main/assets/hadouken.png)

# Hadouken - rapid JSON generator directly inside the ProsgreSQL 9.3+

Let's assume that we have following setup
```ruby
class Company
  has_many :users
end

class User
  belongs_to :company
  has_many :posts, -> { where(published: true) }
end

class Post
  belongs_to :user
end
```
We want our controller
```ruby
class ApiController < ::ApplicationController
  def users_with_posts
    render json: {???}.as_json, status: :ok
  end
end
```
to return a following json
```
{
  "time": "2021-08-26 20:29",
  "users": [
    {
      "uniqueId": 123
      "fullName": "James Smith",
      "companyName": "Best brewery Inc.",
      "posts": [
        {"title": "I really like beer", "description": "Lorem ipsum dolor sit amet..." },
        {"title": "I don't have problems with alcohol", "description": "Lorem ipsum dolor sit amet..."}
      ]
    },
    ...
  ]
}
```
