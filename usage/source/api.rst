API
===

/upstream
---------

GET
~~~
Returns a list of all the upstreams

.. code-block:: javascript
  
  {
    "centos-6.0-os-x86_64": "http://localhost/upstream/centos-6.0-os-x86_64"
  }

POST
~~~~
Creates a new upstream

**Request Body**

.. code-block:: javascript

  {
    "name": "centos-6.0-os-x86_64",
    "path": "poop",
    "type": "yum",
  }

**Response**

* 201 Created 

.. code-block:: javascript

  {
    "uri": "http://localhost/upstream/NAME"
  }

Responds with the URI of where the upstream can be fetched. 

Acceptable types are:

* yum
* apt
* dir

/upstream/NAME
--------------

GET
~~~
Returns the upstream

**Request**

.. code-block:: javascript

  {
    "name": "centos-6.0-os-x86_64",
    "path": "poop",
    "type": "yum",
    "created_at": "2012-03-15T17:45Z"
    "updated_at": "2012-03-15T17:45Z"
  }

PUT
~~~
Updates or creates the upstream. If the upstream already exists, it will trigger a re-sync.

**Request**

.. code-block:: javascript

  {
    "name": "centos-6.0-os-x86_64",
    "path": "poop",
    "type": "yum"
  }

**Response**

* 201 Created on creation.
* 202 Accepted if we are just re-syncing.

.. code-block:: javascript

  {
    "name": "centos-6.0-os-x86_64",
    "path": "poop",
    "type": "yum",
    "updated_at": "2012-03-15T17:45Z"
  }

DELETE
~~~~~~
Removes the upstream. Request has no body.

**Response**

* 200 OK

/upstream/NAME/packages
-----------------------

GET
~~~
Returns a list of all the packages in this upstream.

**Response**

* 200 OK

.. code-block:: javascript

  {
    "08cb7b6e5af66461f7c7c3c66e6a7b75cb152c567d8560eda9f8f2b68bcee1e5": {
      "name": "at",
      "filename": "at-3.1.10-42.el6.i686.rpm",
      "shasum": "...",
      "version": "3.1.0"
    }
  }

/repo
---------

GET
~~~
Returns a list of all the repos.

.. code-block:: javascript
  
  {
    "centos-6.0-os-x86_64-dev": "http://localhost/repo/centos-6.0-os-x86_64-dev"
  }

POST
~~~~
Creates a new repo

**Request Body**

.. code-block:: javascript

  {
    "name": "centos-6.0-os-x86_64-dev",
    "type": "yum"
  }

**Response**

* 201 Created

.. code-block:: javascript

  {
    "uri": "http://localhost/repo/NAME"
  }

Responds with the URI of where the repo can be fetched. 

Acceptable types are:

* yum
* apt
* dir

/repo/NAME
--------------

GET
~~~
Returns the repo

**Request**

.. code-block:: javascript

  {
    "name": "centos-6.0-os-x86_64-dev",
    "type": "yum",
    "updated_at": "2012-03-15T17:45Z"
  }

PUT
~~~
Updates or creates the repo. 

**Request**

.. code-block:: javascript

  {
    "name": "centos-6.0-os-x86_64-dev",
    "path": "poop",
    "type": "yum"
  }

**Response**

* 201 OK on creation.

.. code-block:: javascript

  {
    "name": "centos-6.0-os-x86_64-dev",
    "type": "yum",
    "updated_at": "2012-03-15T17:45Z"
  }

DELETE
~~~~~~
Removes the repo. Request has no body.

**Response**

* 200 OK

/repo/NAME/packages
-------------------

GET
~~~

Get the list of packages in this repo

**Response**

* 200 OK

.. code-block:: javascript

  {
    "08cb7b6e5af66461f7c7c3c66e6a7b75cb152c567d8560eda9f8f2b68bcee1e5": {
      "name": "at",
      "filename": "at-3.1.10-42.el6.i686.rpm",
      "shasum": "...",
      "version": "3.1.0"
    }
  }

PUT
~~~

Set the list of packages in this repo. We take two kinds of request bodies:

**Request**

*Set the list manually*

.. code-block:: javascript

  {
    "08cb7b6e5af66461f7c7c3c66e6a7b75cb152c567d8560eda9f8f2b68bcee1e5": {
      "name": "at",
      "filename": "at-3.1.10-42.el6.i686.rpm",
      "shasum": "...",
      "version": "3.1.0"
    }
  }

*Sync with an upstream or other repo*

.. code-block:: javascript

  {
    "sync": {
      "name": "centos-6.0-os-x86_64",
      "type": "upstream"
    }
  }

**Response**

* 200 OK

/package
---------

GET
~~~

A list of all the packages.

**Response**

* 200 OK

.. code-block:: javascript

  {
    "08cb7b6e5af66461f7c7c3c66e6a7b75cb152c567d8560eda9f8f2b68bcee1e5": "http://localhost/package/08cb7b6e5af66461f7c7c3c66e6a7b75cb152c567d8560eda9f8f2b68bcee1e5",
    "09cb7b6e5af66461f7c7c3c66e6a7b75cb152c567d8560eda9f8f2b68bcee1e5": "http://localhost/package/09cb7b6e5af66461f7c7c3c66e6a7b75cb152c567d8560eda9f8f2b68bcee1e5"
  }

/package/SHASUM
---------------

GET 
~~~

The information we have about the package

**Response**

* 200 OK

.. code-block:: javascript

  {
      "name": "at",
      "filename": "at-3.1.10-42.el6.i686.rpm",
      "shasum": "08cb7b6e5af66461f7c7c3c66e6a7b75cb152c567d8560eda9f8f2b68bcee1e5",
      "version": "3.1.0",
      "upstreams": {
        "centos-6.0-os-x86_64": "http://localhost/upstream/centos-6.0-os-x86_64"
      },
      "repos": {
        "centos-6.0-os-x86_64-dev": "http://localhost/repo/centos-6.0-os-x86_64-dev"
      }
    }
  }

