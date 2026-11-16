# Part 2: Postman collection

Files: `users-posts.postman_collection.json` (the collection) and `jsonplaceholder.postman_environment.json` (holds `baseUrl`, so the host is not hardcoded in any request).

## What it does (run in this order)

| # | Request | Expected | What happens |
| --- | --- | --- | --- |
| 1 | `GET {{baseUrl}}/users` | 200 | Picks the first valid user and stores its id in the collection variable `userId`. |
| 2 | `GET {{baseUrl}}/posts?userId={{userId}}` | 200 | Returns that user's posts. |
| 3 | `GET {{baseUrl}}/posts/{{missingPostId}}` | 404 | `missingPostId` is `99999999`, a post that does not exist. |

## What is checked

All checks live in **one collection-level test script** (nothing is copied per request):

1. Status code per request (200, 200, 404).
2. Every object in the returned arrays validates against a JSON schema. Users require `id`, `name`, `username`, `email`; posts require `userId`, `id`, `title`, `body`; strings must be non-empty.
3. Every returned post has `userId` equal to the selected user.
4. The 404 response is not a populated post (empty body, `{}` or `null`).

## How to run

- **Command line (recommended):** `npm run test:postman` (uses Newman, installed with `npm install`).
- **Postman app:** Import both files, choose the environment "JSONPlaceholder - QA", then run the collection (Runner) so the requests execute in order.

A passing run shows 3 requests and 11 assertions with 0 failed.
