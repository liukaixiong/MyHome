@echo off
set /p project="请输入项目名称: "
cd %project%
echo %cd%
set /p branchName=请输入分支名称: 
echo "开始创建分支"
git pull
git checkout -B %branchName%  origin/develop
git push origin %branchName%
git checkout develop

echo 你的名字是：%project%
echo 你的分支名称: %branchName%
pause