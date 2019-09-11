package com.eboy.redis.config;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;
import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.util.Collection;
import java.util.Enumeration;
import java.util.List;
import java.util.Map;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.data.redis.core.script.RedisScript;
import org.springframework.scripting.support.ResourceScriptSource;
import org.springframework.util.ResourceUtils;

/**
 * @author: eboy
 * @createTime: 19-9-10 上午9:37
 **/
@Configuration
@Slf4j
public class RedisScriptConfig {


    @Bean
    public RedisScriptBuilder redisScriptBuilder(StringRedisTemplate redisTemplate) {
        RedisScriptBuilder redisScriptBuilder = new RedisScriptBuilder();

        ClassPathResource resource = new ClassPathResource("scripts");
        List<Resource> resources= Lists.newLinkedList();
        try {
            URL url = resource.getURL();
            if (ResourceUtils.isJarURL(url)) {
                String[] jarInfo = url.getFile().split("!");
                String jarFilePath = jarInfo[0].substring(jarInfo[0].indexOf("/"));
                System.out.println();
                JarFile jarFile = new JarFile(jarFilePath);

                Enumeration<JarEntry> entries = jarFile.entries();
                while (entries.hasMoreElements()) {
                    JarEntry jarEntry = entries.nextElement();
                    String name = jarEntry.getName();
                    if(name.startsWith("scripts")&&name.endsWith("lua")){
                        ClassPathResource tmp=new ClassPathResource(name);
                        resources.add(tmp);
                    }
                }

            } else {
                File file = resource.getFile();
                File[] files = file.listFiles();
                for (File child : files) {
                    UrlResource urlResource = new UrlResource(child.toURI());
                    resources.add(urlResource);
                }
            }


        } catch (IOException e) {
            log.error("scripts文件不存在");
        }

        for (Resource scriptResource : resources) {
            DefaultRedisScript<String> redisScript = new DefaultRedisScript<String>();
            redisScript.setResultType(String.class);
            redisScript.setScriptSource(new ResourceScriptSource(scriptResource));

            //预加载
            redisTemplate.getConnectionFactory().getConnection()
                    .scriptLoad(redisScript.getScriptAsString().getBytes());

            redisScriptBuilder.putScript(scriptResource.getFilename().replaceAll("\\.lua",""), redisScript);
        }


        return redisScriptBuilder;
    }


    public static class RedisScriptBuilder {

        private Map<String, RedisScript> scriptMap = Maps.newHashMap();

        void putScript(String scriptName, RedisScript redisScript) {
            scriptMap.put(scriptName, redisScript);
        }

        public RedisScript<String> build(String scriptName) {
            return scriptMap.get(scriptName);
        }

        public Collection<RedisScript> getList(String scriptName) {
            return scriptMap.values();
        }
    }


}
