package info.schnatterer.tomcat;

import org.apache.catalina.Context;
import org.apache.catalina.Wrapper;
import org.apache.catalina.startup.Tomcat;

import java.io.File;

public class Main {

    private static final int HTTPS_PORT = 8443;
    public static final String DOMAIN = System.getenv("DOMAIN");
    public static final String CERT_FOLDER = "/certs/";
    public static final String PK = CERT_FOLDER + DOMAIN + "/privkey.pem";
    public static final String CRT = CERT_FOLDER + DOMAIN + "/cert.pem";
    public static final String CA = CERT_FOLDER + DOMAIN + "/fullchain.pem";

    public static void main(String[] args) throws Exception {

        Tomcat tomcat = new Tomcat();
        // Without this call the connector seems not to start
        tomcat.getConnector();

        serveStaticContentFrom(tomcat, "/static");

        ReloadingTomcatConnectorFactory.addHttpsConnector(tomcat, HTTPS_PORT, PK, CRT, CA);

        tomcat.start();
        tomcat.getServer().await();
    }

    private static void serveStaticContentFrom(Tomcat tomcat, String docbase) {
        Context ctx = tomcat.addContext("", new File(docbase).getAbsolutePath());

        Wrapper defaultServlet = ctx.createWrapper();
        defaultServlet.setName("default");
        defaultServlet.setServletClass("org.apache.catalina.servlets.DefaultServlet");
        defaultServlet.addInitParameter("debug", "0");
        defaultServlet.addInitParameter("listings", "false");
        defaultServlet.setLoadOnStartup(1);
        ctx.addChild(defaultServlet);
        ctx.addServletMappingDecoded("/*", "default");
    }
}
