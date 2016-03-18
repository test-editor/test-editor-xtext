package org.testeditor.rcp4.tcltestrun;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.apache.maven.cli.MavenCli;
import org.eclipse.m2e.core.internal.Bundles;
import org.eclipse.m2e.core.internal.MavenPluginActivator;
import org.osgi.framework.Bundle;
import org.osgi.framework.FrameworkUtil;

public class MavenExecutor {

	public void execute(String goal, String pathToPom) {
		System.setProperty("maven.multiModuleProjectDirectory", pathToPom);
		MavenCli cli = new MavenCli();
		cli.doMain(new String[] { goal }, pathToPom, System.out, System.err);
	}

	public void executeInNewJvm(String goal, String pathtoPom) throws IOException {
		String jvm = System.getProperty("java.home") + File.separator + "bin" + File.separator + "java";
		List<String> command = new ArrayList<String>();
		command.add(jvm);
		command.add("-cp");
		command.add(getClassPath());
		command.add(this.getClass().getName());
		command.add(goal);
		command.add(pathtoPom);
		System.out.println(command);
		ProcessBuilder processBuilder = new ProcessBuilder();
		processBuilder.inheritIO();
		processBuilder.command(command);
		Process process = processBuilder.start();
		try {
			process.waitFor();
		} catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	private String getClassPath() {
		List<String> cp = new ArrayList<String>();
		cp.addAll(Bundles.getClasspathEntries(Bundles
				.findDependencyBundle(MavenPluginActivator.getDefault().getBundle(), "org.eclipse.m2e.maven.runtime")));
		Bundle bundle = FrameworkUtil.getBundle(this.getClass());
		cp.addAll(Bundles.getClasspathEntries(bundle));
		Bundle[] bundles = bundle.getBundleContext().getBundles();
		for (String sname : new String[] { "org.slf4j.api", "org.eclipse.m2e.maven.runtime.slf4j.simple",
				"javax.inject" }) {
			Bundle dependency = Bundles.findDependencyBundle(Bundles.findDependencyBundle(
					MavenPluginActivator.getDefault().getBundle(), "org.eclipse.m2e.maven.runtime"), sname);
			if (dependency != null) {
				cp.addAll(Bundles.getClasspathEntries(dependency));
			}
		}
		StringBuffer sb = new StringBuffer();
		sb.append("\"");
		for (String string : cp) {
			sb.append(string).append(File.pathSeparator);
		}
		sb.append("\"");
		return sb.toString();
	}

	public static void main(String[] args) {
		new MavenExecutor().execute(args[0], args[1]);
	}

}
