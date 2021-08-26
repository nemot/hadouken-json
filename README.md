![alt text](https://github.com/nemot/hadouken-json/blob/main/assets/hadouken.png)

# Hadouken - rapid JSON generator directly inside the ProsgreSQL 9.3+

## TL;DR

```ruby
class MyJsonResponse < Hadouken::Json
  attribute :your_variable, String # I'm using Virtus.model, you can pass your argiments here

  def structure
    {
      _title: "Some static title", # Static columns marked with leading underscore
      _myVariable: response_type, # User any string on your chose
      users: array_of({
        companyName: '.company.name', # If value starts from "." char - it's considered to be a field from belongs_to relation
        id: 'id', # Just a column name
        fullName: 'name', # 'fullName' - json key, 'name' - is a column to use
        address: "COALESCE(NULLIF(users.address, ''), users.geolocation)", # You are free to use any sql as a value actually
        
        posts: array_of({
          id: 'id',
          title: 'title',
          fullText: 'description',
          isPublished: 'published',
        }, for: 'posts')
      }, for: relation)
    }
  end

end
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
