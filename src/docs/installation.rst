.. image:: _images/installation.png
   :class: article_cover cover_installation

==================
Installing Spectre
==================

1. Setup Fantom 1.0.57 or newer `from official site <http://fantom.org/doc/docIntro/StartHere.html#quickStart>`_;
2. Download mustache templates from `public github repository <https://github.com/tonsky/mustache>`_::

     >>> hg clone https://bitbucket.org/xored/mustache
   
   and build it::
   
     >>> fan mustache/build.fan

3. Download ``printf`` library from `public bitbucket repository <https://bitbucket.org/prokopov/printf>`_::

     >>> hg clone https://bitbucket.org/prokopov/printf

   and build it::

     >>> fan printf/build.fan

4. Download Spectre from `private bitbucket repository <https://bitbucket.org/xored/spectre/src>`_ (mail `prokopov@xored.com <mailto:prokopov@xored.com>`_ if you need access)::

     >>> hg clone https://<your_username>@bitbucket.org/xored/spectre

   and build it::

     >>> fan spectre/build.fan
  
Congratulations! You now have Spectre installed. Proceed to the :doc:`getting_started` section.