@echo off
set /p project="��������Ŀ����: "
cd %project%
echo %cd%
set /p branchName=�������֧����: 
echo "��ʼ������֧"
git pull
git checkout -B %branchName%  origin/develop
git push origin %branchName%
git checkout develop

echo ��������ǣ�%project%
echo ��ķ�֧����: %branchName%
pause