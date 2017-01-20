import static org.gcube.common.authorization.client.Constants.authorizationService;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import org.gcube.common.authorization.client.proxy.AuthorizationProxy;
import org.gcube.common.authorization.library.provider.ContainerInfo;
import org.gcube.common.authorization.library.provider.SecurityTokenProvider;
 
public class TokenGenerator {
 
	//call with parameters : token host port filePath scope1 ... scopeN
    public static void main(String[] args) {
 
    	String host = args[0];
        String adminToken = args[1];
        int port = Integer.parseInt(args[2]);
        File file = new File(args[3]);
        
        
        try {
            file.createNewFile();
        } catch (IOException e1) {
            System.out.println("error creating file "+file.getAbsolutePath());
            e1.printStackTrace();
            System.exit(10);
	}
          
        ContainerInfo containerInfo =  new ContainerInfo(host, port);
 
        AuthorizationProxy proxy = authorizationService();
 
        try(FileWriter fw = new FileWriter(file)){
            for (int index =4; index<args.length; index++ ){
                SecurityTokenProvider.instance.set(adminToken);
            	try {
                    String token = proxy.requestActivation(containerInfo, args[index] );
                    fw.write("<token>"+token+"</token>\n");
		} catch (Exception e) {
                    System.out.println("error generating token for context "+args[index]);
                    e.printStackTrace();
                } finally{
                	SecurityTokenProvider.instance.reset();
                }
            }
        } catch (Exception e) {
            System.out.println("error writing file "+file.getAbsolutePath());
            e.printStackTrace();
            System.exit(10);	
	}
 
    }
 
}
