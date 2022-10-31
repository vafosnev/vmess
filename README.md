# -Actions-Workflow-V2ray-Ubuntu-
这是借用 actions 产生的虚拟机网络环境从而让我访问国际互联网，FreeVPS-ubuntu-latest 项目被人举报了，github管理员禁用了我的项目，唉，重做吧，可能不会像之前做的那样好了吧，毕竟源码也没有了，重头开始吧。

## 描述
1. 这个项目主要是为了弥补另一个 FreeVPS-ubuntu-latest 项目，因为被管理员禁用，我也是重新制作测试，为了能够正常看 youtube 和 google。  
2. 运行 actions workflow 用于运行脚本，需要添加 `GITHUB_TOKEN` 环境变量，这个是访问 GitHub API 的令牌，可以在 GitHub 主页，点击个人头像，Settings -> Developer settings -> Personal access tokens ，设置名字为 GITHUB_TOKEN 接着要勾选权限，勾选repo、admin:repo_hook和workflow即可，最后点击Generate token，如图所示  
![image](https://user-images.githubusercontent.com/94947393/198914419-0f567e83-03b2-4a33-845f-0039236fb640.png)  
3. 添加 `USER_NAME` 在 GitHub 仓库页 -> Settings -> Secrets -> actions -> New repository secret  
4. 添加 `USER_PW` 在 GitHub 仓库页 -> Settings -> Secrets -> actions -> New repository secret  
5. 添加 `HOST_NAME` 在 GitHub 仓库页 -> Settings -> Secrets -> actions -> New repository secret  
6. 添加 `NGROK_AUTH_TOKEN` 在 GitHub 仓库页 -> Settings -> Secrets -> actions -> New repository secret  
7. 添加 `MAILUSERNAME` 在 GitHub 仓库页 -> Settings -> Secrets -> actions -> New repository secret  
8. 添加 `MAILPASSWORD` 在 GitHub 仓库页 -> Settings -> Secrets -> actions -> New repository secret  
9. 添加 `MAILSENDTO` 在 GitHub 仓库页 -> Settings -> Secrets -> actions -> New repository secret  
10. 转到 Actions -> -Actions-Workflow-V2ray-Ubuntu- 并且启动 workflow，实现自动化  
11. 新修改目录结构  

        .
        ├── getorupdatefile.sh                          # 搭建脚本  
        └── README.md                                   # 这个是说明文件   
    
9. 出于安全考虑还是使用邮箱把发送内容发给自己的邮箱  
10. 这次能维持6h挺好  
