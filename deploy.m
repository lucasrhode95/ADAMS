%creates function BUILDDATE which returns the date of compilation
import util.CommonsUtil;

fid = fopen('builddate.m','w');
fprintf(fid, 'function s = builddate\n');
fprintf(fid, 's=''%s'';\n', CommonsUtil.getTimestamp);
fclose(fid);

%do the actual compiling
deploytool -build ADAMS_en/ADAMS_installer.prj