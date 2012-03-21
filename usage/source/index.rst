.. metarepo documentation master file, created by
   sphinx-quickstart on Tue Mar 13 12:14:56 2012.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to metarepo's documentation!
====================================

* We track "upstreams"
* Files appear in the upstrem
* Get added to the pool
* Repos get created from packages in the pool
  * Can be synced to an upstream
  * Can be synced to another repo
  * Can have a specific policy

.. graphviz:: 

  digraph build_chain {
    upstream [label="centos-6-os-x86_64"];
    makerepo [label="centos-6-os-x86_64-20111210"];
    development [label="set dev env"];
    production [label="set prod env"];

    "upstream" -> "makerepo";
    "makerepo" -> "development";
    "development" -> "production";
  }

Contents:

.. toctree::
  :maxdepth: 2

  api
  database_design


Indices and tables
==================

* :ref:`genindex`
* :ref:`search`

