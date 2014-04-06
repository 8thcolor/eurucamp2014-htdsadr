## List project repository tags

Get a list of repository tags from a project, sorted by name in reverse alphabetical order.

```
GET /projects/:id/repository/tags
```

Parameters:

+ `id` (required) - The ID of a project

```json
[
  {
    "name": "v1.0.0",
    "commit": {
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "parents": [],
      "tree": "38017f2f189336fe4497e9d230c5bb1bf873f08d",
      "message": "Initial commit",
      "author": {
        "name": "John Smith",
        "email": "john@example.com"
      },
      "committer": {
        "name": "Jack Smith",
        "email": "jack@example.com"
      },
      "authored_date": "2012-05-28T04:42:42-07:00",
      "committed_date": "2012-05-28T04:42:42-07:00"
    },
    "protected": null
  }
]
```

## List repository tree

Get a list of repository files and directories in a project.

```
GET /projects/:id/repository/tree
```

Parameters:

+ `id` (required) - The ID of a project
+ `path` (optional) - The path inside repository. Used to get contend of subdirectories
+ `ref_name` (optional) - The name of a repository branch or tag or if not given the default branch

```json
[
  {
    "name": "assets",
    "type": "tree",
    "mode": "040000",
    "id": "6229c43a7e16fcc7e95f923f8ddadb8281d9c6c6"
  },
  {
    "name": "contexts",
    "type": "tree",
    "mode": "040000",
    "id": "faf1cdf33feadc7973118ca42d35f1e62977e91f"
  },
  {
    "name": "controllers",
    "type": "tree",
    "mode": "040000",
    "id": "95633e8d258bf3dfba3a5268fb8440d263218d74"
  },
  {
    "name": "Rakefile",
    "type": "blob",
    "mode": "100644",
    "id": "35b2f05cbb4566b71b34554cf184a9d0bd9d46d6"
  },
  {
    "name": "VERSION",
    "type": "blob",
    "mode": "100644",
    "id": "803e4a4f3727286c3093c63870c2b6524d30ec4f"
  },
  {
    "name": "config.ru",
    "type": "blob",
    "mode": "100644",
    "id": "dfd2d862237323aa599be31b473d70a8a817943b"
  }
]
```


## Raw file content

Get the raw file contents for a file by commit sha and path.

```
GET /projects/:id/repository/blobs/:sha
```

Parameters:

+ `id` (required) - The ID of a project
+ `sha` (required) - The commit or branch name
+ `filepath` (required) - The path the file


## Raw blob content

Get the raw file contents for a blob by blob sha.

```
GET /projects/:id/repository/raw_blobs/:sha
```

Parameters:

+ `id` (required) - The ID of a project
+ `sha` (required) - The blob sha


## Get file archive

Get a an archive of the repository

```
GET /projects/:id/repository/archive
```

Parameters:
+ `id` (required) - The ID of a project
+ `sha` (optional) - The commit sha to download defaults to the tip of the default branch
