.. image:: _images/installation.png
   :class: article_cover cover_installation

==================
Installing Spectre
==================

1. Setup Fantom 1.0.56 or newer `from official site <http://fantom.org/doc/docIntro/StartHere.html#quickStart>`_;
2. Download mustache templates from `public github distr <https://github.com/tonsky/mustache>`_::

     >>> git clone https://github.com/tonsky/mustache.git
   
   and build it::
   
     >>> fan mustache/build.fan

3. Download Spectre from `private bitbucket repository <https://bitbucket.org/xored/spectre/src>`_::

     >>> hg clone https://<your_username>@bitbucket.org/xored/spectre

   and build it::

     >>> fan spectre/build.fan
  
Congratulations! You now have Spectre installed. Move onto :doc:`getting_started` section.