package com.eboy.redis;

import static org.springframework.util.ResourceUtils.URL_PROTOCOL_FILE;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.io.ClassPathResource;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.util.ResourceUtils;

/**
 * @author: eboy
 * @createTime: 19-9-10 上午10:23
 **/
@RunWith(SpringRunner.class)
@SpringBootTest
public class FileLoadTest {

    @Test
    public void loadFile() throws IOException {
        ClassPathResource resource = new ClassPathResource("support");
        String filename = resource.getFilename();
        System.out.println(filename);
        URL url = resource.getURL();
        System.out.println(url);
        if(ResourceUtils.isJarURL(url)){
            String[] jarInfo = url.getFile().split("!");
            String jarFilePath = jarInfo[0].substring(jarInfo[0].indexOf("/"));
            String packagePath = jarInfo[1].substring(1);
            System.out.println();
            JarFile jarFile = new JarFile(jarFilePath);

            Enumeration<JarEntry> entries = jarFile.entries();
            while (entries.hasMoreElements()){
                JarEntry jarEntry = entries.nextElement();
                String name = jarEntry.getName();
                System.out.println(name);

                if(name.startsWith("support")){
                    if(name.lastIndexOf('/')==name.length()-1){
                        name=name.substring(0,name.length()-1);
                    }

                    ClassPathResource tmpFile = new ClassPathResource( name);
                    System.out.println(tmpFile.getURL());
                    System.out.println(tmpFile.getFilename());
                }

            }

        }else {
            File file = resource.getFile();
            File[] files = file.listFiles();
            for (File file1 : files) {
                System.out.println(file1.getAbsolutePath());
            }
        }



    }

}
