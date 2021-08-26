![alt text](https://github.com/nemot/hadouken-json/blob/main/assets/hadouken.png)

# Hadouken - rapid JSON generator directly inside the ProsgreSQL 9.3+

## TL;DR

```ruby
class MyJsonResponse < Hadouken::Json
  attribute :my_var, String # I'm using Virtus.model, you can pass your arguments like that

  def structure
    {
      # Static columns marked with leading underscore
      _title: "Some static title",
      _myVariable: my_var,

      users: array_of({
        companyName: '.company.name', # A name field from, the company (belongs_to association)
        id: 'id',
        fullName: 'name', # name - is a column name
        address: "COALESCE(NULLIF(users.address, ''), users.geolocation)",

        posts: array_of({
          id: 'id',
          title: 'title',
          fullText: 'description',
          isPublished: 'published',
        }, for: 'posts') # 'for' could be a relation or a string with relation name

      }, for: relation)
    }
  end
end

MyJsonResponse.call(relation: User.all, my_var: 'anything') # => JSON string
```

## Long story
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
