# install
The software installer program used to build many VEuPathDB backend systems and the VEuPathDB websites.  It is ant-based.  It reads from source code residing in the directory pointed to by the $PROJECT_HOME environment variable.  It builds and installs executable software into the directory pointed to by the $GUS_HOME environment variable.  It builds and installs website resource into the location provided to its command line interface in `webapp.props`.

The heart of the install system is this [build.xml](build.xml) file, written in [Ant XML](https://ant.apache.org/manual/using.html).  Projects build by the install system provide their own `build.xml` file (for example [WDK/build.xml](https://github.com/VEuPathDB/WDK/build.xml)), which call the utility targets provided here.

Website resources can be bundled using a common [webpack](https://webpack.js.org/) configuration, including support for [TypeScript](https://www.typescriptlang.org/) and [Sass](https://sass-lang.com/). This is done by placing a `webpack.config.js` file in either a project or component directory, and extending [base.webpack.org](./base.webpack.org). The installer program will detect this file and execute the `webpack` program.

## Dependencies
 * Ant 1.9
 * Maven
 * NodeJS >= 8

## Usage
```
~ [0]$ bld

Build an executable from $PROJECT_HOME into $GUS_HOME

Usage: bld project[/component] [-publishDocs]

  calls 'build project[/component] install -append'

The -publishDocs flag, if present, will be passed to build as well

~ [1]$ bldw

Build an executable from $PROJECT_HOME into $GUS_HOME and install web resources according to webPropFile 

Usage: bldw project webPropFile [-publishDocs]

Example:  bldw GiardiaDBWebsite project_home/webapp.prop

  calls 'build GiardiaDBWebsite webinstall -append -webPropFile project_home/webapp.prop'

The -publishDocs flag, if present, will be passed to build as well
```

