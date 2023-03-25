package info.schnatterer.tomcat;

import org.apache.catalina.Context;
import org.apache.catalina.Wrapper;
import org.apache.catalina.startup.Tomcat;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.io.Writer;

public class Main {

    private static final int HTTPS_PORT = 8443;
    public static final String DOMAIN = System.getenv("DOMAIN");
    public static final String CERT_FOLDER = System.getenv("CERT_DIR");
    public static final String PK = CERT_FOLDER + DOMAIN + "/privkey.pem";
    public static final String CRT = CERT_FOLDER + DOMAIN + "/cert.pem";
    public static final String CA = CERT_FOLDER + DOMAIN + "/fullchain.pem";

    public static void main(String[] args) throws Exception {

        Tomcat tomcat = new Tomcat();
        // Without this call the connector seems not to start
        tomcat.getConnector();

        Context ctx = tomcat.addContext("", new File("/static").getAbsolutePath());

        Tomcat.addServlet(ctx, "HelloServlet", new HttpServlet() {
            @Override
            protected void service(HttpServletRequest req, HttpServletResponse resp)throws IOException {
                Writer w = resp.getWriter();
                w.write("Hello Embedded Tomcat.\n");
                w.flush();
                w.close();
            }
        });
        ctx.addServletMappingDecoded("", "HelloServlet");
        
        serveStaticContentFrom(ctx);

        ReloadingTomcatConnectorFactory.addHttpsConnector(tomcat, HTTPS_PORT, PK, CRT, CA);

        tomcat.start();
        tomcat.getServer().await();
    }

    private static void serveStaticContentFrom(Context ctx) {
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
