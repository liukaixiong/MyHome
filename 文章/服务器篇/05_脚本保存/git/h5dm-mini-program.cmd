@echo off
cd h5dm-mini-program
echo %cd%
set /p branchName=�������֧����: 
echo "��ʼ������֧"
git pull
git checkout -B %branchName%  origin/develop
git push origin %branchName%
git checkout develop

echo "��֧������� ...."
pause