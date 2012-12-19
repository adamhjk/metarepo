.. metarepo documentation master file, created by
   sphinx-quickstart on Tue Mar 13 12:14:56 2012.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to metarepo's documentation!
====================================

Metarepo is a "meta-repository" management system. It:

* Tracks "upstream" sources of packages, such as a local CentOS/Ubuntu mirror, or simply directories full of package files.
* Imports packages from the upstreams into a single managed "pool".
* Allows you to create arbitrary numbers of "repos", which can then be used by regular downstream package management tools.

.. graphviz::

  digraph workflow {
    "N upstreams" -> "pool" -> "N repos";
  }

.. warning::

  Metarepo is **alpha** software. It works, but it has lots of rough edges. If you
  aren't feeling like rolling up your sleeves and going code-diving when things get
  weird, probably not quite ready for you yet. If you **are** ready to do that, and
  it sounds cool, now is a good time to dive in.

*	We track "upstreams"
* Files appear in the upstream
* Get added to the pool
* Repos get created from packages in the pool

  * Can be synced to an upstream
  * Can be synced to another repo
  * Can have a specific policy

Contents:

.. toctree::
  :maxdepth: 2

  install
  api


Indices and tables
==================

* :ref:`genindex`
* :ref:`search`

