/*
 * Created on Feb 3, 2005
 */

package org.gusdb.install;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;
import java.util.Properties;
import org.apache.tools.ant.Task;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.tools.ant.BuildException;

/**
 * @author msaffitz
 * @version $Revision$ $Date$
 */
public class WritePropertyFileTask extends Task {
	
	private static Log log = LogFactory.getLog(WritePropertyFileTask.class);
	private Properties props;
	private String projectHome;
	private String gusConfigFile;
	
	public void setProjectHome(String projectHome) {
	    this.projectHome = projectHome;
	}
	
	public void setGusConfigFile(String gusConfigFile) {
	    this.gusConfigFile = gusConfigFile;
	}
	
	public void execute() throws BuildException {
	    initialize();
	    writeGusProp(false);
	    writeInstallProp(true);
		writePluginProp(true);
	}
	
	private void writeGusProp(boolean overwrite) {

		File gusProp = new File( gusConfigFile );
		if ( gusProp.exists() && ! overwrite ) {
			log.info("Skipping creation of GUS_CONFIG_FILE " + gusConfigFile + " -- already exists");
			return;
		}
		try {
			if ( gusProp.exists()) {
				log.info("Recreating $GUS_CONFIG_FILE");
				gusProp.delete();
				gusProp.createNewFile();
			}
			FileWriter writer = new FileWriter(gusProp);
			writeProperty(writer, "databaseLogin");
			writeProperty(writer, "databasePassword");
			writeProperty(writer, "databaseLogin", "readOnlyDatabaseLogin");
			writeProperty(writer, "databasePassword", "readOnlyDatabasePassword");
			writeProperty(writer, "coreSchemaName");
			writeProperty(writer, "userName");
			writeProperty(writer, "group");
			writeProperty(writer, "project");
			writeProperty(writer, "dbiDsn");
			writer.close();
		} catch (IOException e) {
			log.fatal("Error in writing gus.properties file", e);
			throw new RuntimeException("Error in writing gus.properties file", e);
		}
		
	}
/*
	public static void writeSchemaProp(boolean overwrite) {
		if ( props == null ) { initialize(); }
		
		File schemaProp = new File( System.getProperty("PROJECT_HOME") + "/install/config/schema.prop" );
		if ( schemaProp.exists() && ! overwrite ) {
			log.info("Skipping creation of install.prop file: already exists");
			return;
		}
	}
*/	
	private void writeInstallProp(boolean overwrite) {

	    File installProp = new File( projectHome + "/install/config/install.prop" );
		if ( installProp.exists() && ! overwrite ) {
			log.info("Skipping creation of install.prop file: already exists");
			return;
		}
		try {
			if ( installProp.exists()) {
				log.info("Recreating install.prop file");
				installProp.delete();
				installProp.createNewFile();
			}
			FileWriter writer = new FileWriter(installProp);
			writeProperty(writer, "perl");
			writer.close();
		} catch (IOException e) {
			log.fatal("Error in writing install.prop file", e);
			throw new RuntimeException("Error in writing install.prop file", e);
		}
	}
	
	private void writePluginProp(boolean overwrite) {
	    File propFile = new File( projectHome + "/install/config/GUS-PluginMgr.prop");
		if ( propFile.exists() && ! overwrite ) {
			log.info("Skipping creation of GUS-PluginMgr.prop file: already exists");
			return;
		}
		try {
			if ( propFile.exists()) {
				log.info("Recreating GUS-PluginMgr.prop file");
				propFile.delete();
				propFile.createNewFile();
			}
			FileWriter writer = new FileWriter(propFile);
			writeProperty(writer, "md5sum");
			writer.close();
		} catch (IOException e) {
			log.fatal("Error in writing PluginMgr.prop file", e);
			throw new RuntimeException("Error in writing PluginMgr.prop file", e);
		}
	}
	
	private void writeProperty(Writer writer, String key) {
		writeProperty(writer, key, key, true);
	}
	
	private void writeProperty(Writer writer, String key, String fileKey ) {
		writeProperty(writer, key, fileKey, true);
	}
	
	private void writeProperty(Writer writer, String key, String fileKey, boolean required) {
		if ( props == null ) {
			log.fatal("Properties have not been instantiated.");
			throw new RuntimeException("Properties have not been instantiated");
		}
		if ( props.getProperty(key) == null && required ) {
			log.fatal("Required property '" + fileKey + "' is not set.");
			throw new RuntimeException("Required property '" + fileKey + "' is not set.");
		}
		try {
			writer.write(fileKey + "=" + props.getProperty(key) + "\n");
		} catch (IOException e) {
			log.fatal("Unable to write property '" + key + "' with value '" + props.getProperty(key) + "'.",e);
			throw new RuntimeException("Unable to write property '" +
								key + "' with value '" + props.getProperty(key) + "'.",e);
		}
	}
		
	private Properties initialize() {
		File propertyFile;
		props = new Properties();

		try {
			propertyFile = new File( projectHome + "/install/gus.config");
			props.load(new FileInputStream(propertyFile));
		} catch (IOException e) {
			log.error("Could not read " + projectHome + "/install/gus.config", e);
			throw new RuntimeException(e);
		}
		
		File configDir = new File( projectHome + "/install/config" );
		if (  ! configDir.exists() ) {
			log.info("Creating configuration directory");
			configDir.mkdir();
		}
		
		return props;
	}
	
}
