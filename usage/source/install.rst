Installation
============

Install required packages
-------------------------

* PostgreSQL (if you want to run tests, you need to have working ident auth)
* Redis

Clone the source
----------------

.. code-block:: bash
  
  git clone http://github.com/adamhjk/metarepo

Bundle Dance
------------

.. code-block:: bash
 
  cd ./metarepo
  bundle install

Create the database
-------------------

.. code-block:: bash

  bundle exec sequel -m ./migrations postgresql://localhost/metarepo

Start the REST API
------------------

.. code-block:: bash

  bundle exec ./bin/metarepo-rest -F

Start the Resque worker
-----------------------

.. code-block:: bash
  
  bundle exec rake resque:work


