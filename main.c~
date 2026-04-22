#include <stdio.h>
#include <sys/stat.h>
#include <string.h>
#include <sys/types.h>
#include <openssl/sha.h>
#include <time.h>
#include <unistd.h>
#include <dirent.h>

#define HASH_SIZE 41
#define BUFFER_SIZE 1024

/*=====================================
        CHECK REPOSITORY
  ====================================*/

 int repo_exists(){

  struct stat st;

  // checking myvcs exist or not
  
  if(stat(".myvcs",&st) != 0){

    return 0;   //myvcs doesnot exist 
  }

  //check if its actually a directory 
  if(!S_ISDIR(st.st_mode)){

    return 0;  // myvcs not a directory
  }
  
  return 1;
}

/*=====================================
	  GENERATE HASH FILE 
 =====================================*/					  
					 
void generate_sha1_file(const char *file_name,char *output){

  unsigned char hash[SHA_DIGEST_LENGTH];
  SHA_CTX sha1;

  FILE *file = fopen(file_name,"rb");
  SHA1_Init(&sha1);

  char buffer[BUFFER_SIZE];
  int bytes;

  while((bytes = fread(buffer,1,BUFFER_SIZE,file))>0){
    SHA1_Update(&sha1,buffer,bytes);
  }

  SHA1_Final(hash,&sha1);
  fclose(file);

  for(int i=0;i<SHA_DIGEST_LENGTH;i++){
    sprintf(output + (i*2),"%02x",hash[i]);
  }

  output[40] = '\0';
  
}

/*=======================================
        GENERATE HASH COMMIT 
  =======================================*/
					
void generate_sha1_string(char *data,char *output){

  unsigned char hash[SHA_DIGEST_LENGTH];

  SHA1((unsigned char*)data, strlen(data),hash);

  for(int i=0;i<SHA_DIGEST_LENGTH;i++){
    sprintf(output + (i*2),"%02x",hash[i]);
  }

  output[40] = '\0';

}

/*========================================
        REPOSITORY INITIALISATION   
  ========================================*/
  
void init_repo(char *repo_name ){
  struct stat st = {0};
  
  if(stat(repo_name,&st)==0){
    printf("repository already initialised.\n");
    return;
  }
  mkdir(repo_name,0777);
  char path[256];
  
  // .myvcs
  sprintf(path,"%s/.myvcs",repo_name);
  mkdir(path,0777);
  
  // .myvcs/objects
  sprintf(path,"%s/.myvcs/objects",repo_name);
  mkdir(path,0777);

  // .myvcs/commits
  sprintf(path,"%s/.myvcs/commits",repo_name);
  mkdir(path,0777);

  // .myvcs/refs
  sprintf(path,"%s/.myvcs/refs",repo_name);
  mkdir(path,0777);

  // refs/heads
  sprintf(path,"%s/.myvcs/refs/heads",repo_name);
  mkdir(path,0777);
  

  // myvcs/index
  sprintf(path,"%s/.myvcs/index",repo_name);
  FILE *index = fopen(path,"w");
  if(index != NULL){
    fclose(index);
  }

  //main_branch
  sprintf(path,"%s/.myvcs/refs/heads/master",repo_name);
  FILE *main_branch = fopen(path,"w");
  if(main_branch != NULL){
    fprintf(main_branch,"NULL\n");
    fclose(main_branch);
  }
  
  // .myvcs/HEAD
  sprintf(path,"%s/.myvcs/HEAD",repo_name);
  FILE *head = fopen(path,"w");
  if(head != NULL){
    fprintf(head ,"ref: refs/heads/master\n");
    fclose(head);
  }
  printf("Repository intialised succesfully.\n");
}

/*==========================================
        FILE SEND TO STAGING AREA  
  ==========================================*/
  
void add_file(char *file_name){

  if(repo_exists() == 0){
    printf("Error: Not a myvcs repository.\n");
    return;
  }

  struct stat st;
  if(stat(file_name,&st) != 0){
    printf("Error: File does not exist.\n");
    return;
  }	   

  if(S_ISDIR(st.st_mode)){
    printf("Error: %s is Directory,only files are supported.\n",file_name);
  }

  // generating hash
  
  char hash[HASH_SIZE];
  generate_sha1_file(file_name,hash);

  // STORE OBJECTS //

  char object_path[256];
  sprintf(object_path,".myvcs/objects/%s",hash);

  struct stat st1;
  if(stat(object_path,&st1) != 0){

    FILE *src = fopen(file_name,"rb");
    FILE *dest = fopen(object_path,"wb");

    if(src == NULL || dest ==  NULL){
      printf("Error in storing object.\n");
    }

    char buffer[BUFFER_SIZE];
    size_t bytes;

    while((bytes = fread(buffer,1,BUFFER_SIZE,src)) > 0){
	fwrite(buffer,1,bytes,dest);
	//printf("Read %zu bytes\n",bytes);
    }
    
    fclose(src);
    fclose(dest);
  }


  /* ==== UPDATE INDEX ==== */

  FILE * index = fopen(".myvcs/index","r");
  FILE * index_temp = fopen(".myvcs/index_temp","w");

  char line[512];
  int found = 0;

  while(fgets(line,sizeof(line),index) != NULL){

    char existing_file[256];
    char existing_hash[HASH_SIZE];

    sscanf(line,"%s %s",existing_file,existing_hash);

    if(strcmp(existing_file,file_name)==0){
      fprintf(index_temp,"%s %s\n",file_name,hash);
      found = 1;
    }
    else{
      fputs(line,index_temp);
    }
    
  }
  
  fclose(index);
  
  if(found == 0){
    fprintf(index_temp,"%s %s\n",file_name,hash);
  }

  fclose(index_temp);
  
  remove(".myvcs/index");
  rename(".myvcs/index_temp",".myvcs/index");

  printf("%s added succesfully.\n",file_name);
  
}

/*=====================================
	  COMMIT MESSAGE
  =====================================*/
					
void commit(const char *message){

  if(!repo_exists()){
    printf("Not a repository.\n");
    return;
  }
  
  FILE * index = fopen(".myvcs/index","r");
  if(!index){
    printf("Nothing to commit.\n");
    return;
  }

  fseek(index,0,SEEK_END);
  if(ftell(index) == 0){
    printf("Nothing staged.\n");
    fclose(index);
    return;
  }
  rewind(index);

  char parent_hash[HASH_SIZE] = "";
  FILE *master = fopen(".myvcs/refs/heads/master","r");
  if(master){
    fgets(parent_hash,HASH_SIZE,master);
    parent_hash[strcspn(parent_hash,"\n")] = 0;
    fclose(master);
  }
  
  char commit_content[10000] = "";
  char line[500];

  sprintf(commit_content,"parent: %s\n""message: %s\n""timestamp: %ld\n\n",parent_hash,message,time(NULL));

  while(fgets(line,sizeof(line),index))
    strcat(commit_content,line);

  fclose(index);

  char commit_hash[HASH_SIZE];
  generate_sha1_string(commit_content,commit_hash);

  char commit_path[200];
  sprintf(commit_path,".myvcs/commits/%s",commit_hash);

  FILE *commit_file = fopen(commit_path,"w");
  fprintf(commit_file,"%s",commit_content);
  fclose(commit_file);

  FILE *master_update = fopen(".myvcs/refs/heads/master","w");
  fprintf(master_update,"%s",commit_hash);
  fclose(master_update);

  /* clear staging area */
  FILE *clear = fopen(".myvcs/index","w");
  fclose(clear);
  
  printf("Committed as %s\n",commit_hash);

}
      
/*=====================================
	        STATUS  
  =====================================*/

void status(){
  if(!repo_exists()){
     printf("Not a repository.\n");
     return;
   }

   printf("------- MYVCS STATUS -------\n\n");
   
   char head_commit[HASH_SIZE] = "";
   FILE *master = fopen(".myvcs/refs/heads/master","r");
   if(master){
     fgets(head_commit,HASH_SIZE,master);
     head_commit[strcspn(head_commit,"\n")] = 0;
     fclose(master);
   }

   FILE *index = fopen(".myvcs/index","r");

   printf("--------Staged Files--------\n");

   int staged_empty = 1;
   if(index){
     char file[256]; char hash[HASH_SIZE];
     while(fscanf(index,"%s %s",file,hash)==2){
       printf(" %s\n",file);
       staged_empty = 0;
     }
     fclose(index);
   }
   if(staged_empty) printf(" None\n");

   printf("\n---- Modified but not staged ----\n");

   DIR *dir = opendir(".");
   struct dirent *entry;

   int modified_empty = 1;

   while((entry = readdir(dir)) != NULL){

     if(strcmp(entry->d_name,".")==0 || strcmp(entry->d_name,"..")==0
	|| strcmp(entry->d_name,".myvcs") == 0)
       continue;

     struct stat st;
     if(stat(entry->d_name,&st) != 0)
       continue;

     if(S_ISREG(st.st_mode)){

       char current_hash[HASH_SIZE];
       generate_sha1_file(entry->d_name,current_hash);

       FILE *idx = fopen(".myvcs/index","r");
       char file[256]; char hash[HASH_SIZE];

       int found = 0;

       if(idx){
	 while(fscanf(idx,"%s %s",file,hash)==2){
	   if(strcmp(file,entry->d_name)==0){
	     found = 1;
	     if(strcmp(hash,current_hash) != 0){
	       printf(" %s (modified)\n",entry->d_name);
	       modified_empty = 0;
	     }
	   }
	 }
	 fclose(idx);
       }

       if(!found && strlen(head_commit)>0){

	 char commit_path[256];
	 sprintf(commit_path,".myvcs/commits/%s",head_commit);

	 FILE *commit = fopen(commit_path,"r");
	 if(commit){
	   char line[512];
	   int header_done = 0;

	   while(fgets(line,sizeof(line),commit)){
	     if(strcmp(line,"\n")==0){
	       header_done = 1;
	       continue;
	     }
	     
	     if(!header_done) continue;

	     char commit_file[256]; char commit_hash[HASH_SIZE];
	     sscanf(line,"%s %s",commit_file,commit_hash);

	     if(strcmp(commit_file,entry->d_name)==0){
	       if(strcmp(commit_hash,current_hash)==0){
		 printf(" %s (modified)\n",entry->d_name);
		 modified_empty = 0;
	       }
	     }
	   }
	   fclose(commit);
	 }
       }
     }
   }
   closedir(dir);
   
   if(modified_empty)
     printf(" None\n");
   
   printf("\n--------- Untracked files --------\n");
   
   dir = opendir(".");
   int untracked_empty = 1;
   
   while((entry = readdir(dir)) != NULL){
     
     if(strcmp(entry->d_name,".")==0 || strcmp(entry->d_name,".")==0 ||
	strcmp(entry->d_name,".myvcs")==0){
       continue;
     }
     
       struct stat st;
       if(stat(entry->d_name,&st)!=0)
	 continue;
       
       if(S_ISREG(st.st_mode)){
	 
	 FILE *idx = fopen(".myvcs/index","r");
	 int tracked = 0;
	 char file[256];char hash[HASH_SIZE];
	 
	 if(idx){
	   while(fscanf(idx,"%s %s",file,hash)==2){
	     if(strcmp(file,entry->d_name)==0)
	       tracked = 1;
	   }
	   fclose(idx);
	 }
	 
	 if(!tracked && strlen(head_commit)>0){
	   
	   char commit_path[256];
	   sprintf(commit_path,".myvcs/commits/%s",head_commit);
	   
	   FILE *commit = fopen(commit_path,"r");
	   if(commit){
	     char line[512];
	     int header_done = 0;
	     
	     while(fgets(line,sizeof(line),commit)){
	       if(strcmp(line,"\n")==0){
		 header_done = 1;
		 continue;
	       }
	       if(!header_done) continue;
	       
	       sscanf(line,"%s %s",file,hash);
	       if(strcmp(file,entry->d_name)==0)
		 tracked = 1;
	     }
	     fclose(commit);
	   }
	 }

	 if(!tracked){
	   printf(" %s\n",entry->d_name);
	   untracked_empty = 0;
	 }
       }
   }
   closedir(dir);
   
   if(untracked_empty)
     printf(" None\n");
   
   printf("\n==============================\n");
}
     
/* ======================================
              PRINT LOG HISTORY
   ======================================*/
void log_history(){

  if(!repo_exists()){
    printf("Not a repository.\n");
    return;
  }

  FILE *master = fopen(".myvcs/refs/heads/master","r");
  if(!master) return;

  char commit_hash[HASH_SIZE] = "";
  fgets(commit_hash,HASH_SIZE,master);
  commit_hash[strcspn(commit_hash,"\n")] =0;
  fclose(master);

  while(strlen(commit_hash)>0){

  char path[200];
  sprintf(path,".myvcs/commits/%s",commit_hash);

  FILE *commit = fopen(path,"r");
  if(!commit) return;

  printf("Commit: %s\n",commit_hash);
  
  char line[500];
  char parent[HASH_SIZE] = "";
  
while(fgets(line,sizeof(line),commit)) {

  if(strncmp(line,"parent:",7)==0)
    sscanf(line,"parent: %s",parent);

  if(strncmp(line,"message:",8) == 0 || strncmp(line,"timestamp:",10) == 0){
    printf("%s",line);
  }

 }
    
  printf("\n");
  fclose(commit);

  strcpy(commit_hash,parent);
 }

}

 /*===================================
                CHECKOUT
   ===================================*/
  
void checkout(const char *target_hash){
  
  if(!repo_exists()){
    printf("Not a repository.\n");
    return;
  }
  
  char path[200];
  sprintf(path,".myvcs/commits/%s",target_hash);
  
  FILE *commit = fopen(path,"r");
  if(!commit){
    printf("Commit not found.\n");
    return ;
  }
  
  char line[500];
  int header_done = 0;
  char filename[200],hash[41];
  
  while(fgets(line,sizeof(line),commit)){
    
    if(strcmp(line,"\n") == 0){
      header_done = 1;
      continue;
    }
    
      if(!header_done) continue;
      
      sscanf(line,"%s %s",filename,hash);
      
      char object_path[200];
      sprintf(object_path,".myvcs/objects/%s",hash);
      
      FILE * src = fopen(object_path,"rb");
      FILE * dest = fopen(filename,"wb");
      
      if(!src || !dest) continue;
      
      char buffer[BUFFER_SIZE];
      size_t bytes;				\
      
      
      while((bytes = fread(buffer,1,BUFFER_SIZE,src))>0)
	fwrite(buffer,1,bytes,dest);
      
      fclose(src);
      fclose(dest);
      
  }
  fclose(commit);
  
  FILE * master = fopen(".myvcs/refs/heads/master","w");
  fprintf(master,"%s",target_hash);
  fclose(master);
  
  printf("Checked out %s\n",target_hash);
}
/*===============================
         DIFF
  ===============================*/

void diff(const char *filename){
  if(!repo_exists()){
    printf("Not a myvcs repository.\n");
    return;
  }

  struct stat st;
  if(stat(filename,&st) != 0){
    printf("File doesnot exist.\n");
    return;
  }

  /*GET HEAD COMMIT*/
  char head_hash[HASH_SIZE] = "";
  FILE *master = fopen(".myvcs/refs/heads/master","r");
  if(master){
    fgets(head_hash,HASH_SIZE,master);
    head_hash[strcspn(head_hash,"\n")]=0;
    fclose(master);
  }

  if(strlen(head_hash) == 0 || strcmp(head_hash,"NULL")==0){
    printf("No commits done yet.\nUse myvcs commit <file> to commit file.\n");
    return;
  }

  /*Open commit file */
  char commit_path[256];
  sprintf(commit_path,".myvcs/commits/%s",head_hash);

  FILE * commit = fopen(commit_path,"r");
  if(!commit){
    printf("Commit not found.\n");
    return;
  }

  char line[512];
  int header_done = 0;
  char file[256];char hash[HASH_SIZE];
  int found = 0;

  while(fgets(line,sizeof(line),commit)){
    if(strcmp(line,"\n")==0){
      header_done = 1;
      continue;
    }

    if(!header_done) continue;

    sscanf(line,"%s %s",file,hash);

    if(strcmp(file,filename) == 0){
      found = 1;
      break;
    }
  }
  fclose(commit);

  if(!found){
    printf("File not tracked in last commit.\n");
    return;
  }

  /* Open file in objects*/
  char object_path[256];
  sprintf(object_path,".myvcs/objects/%s",hash);

  FILE *old = fopen(object_path,"r");
  FILE *current = fopen(filename,"r");

  if(!old || !current){
    printf("Error in opening files.\n");
    return;
  }

  printf("Diff for %s:\n\n",filename);
  
  char oldline[512];
  char newline[512];

  while(1){

    char *o = fgets(oldline,sizeof(oldline),old);
    char *n = fgets(newline,sizeof(newline),current);

    if(!o && !n){
      break;
    }

    if(o && !n){
      printf("- %s\n",oldline);
    }
    else if(!o && n){
      printf("+ %s\n",newline);
    }
    else if(strcmp(oldline,newline) != 0){
      printf("- %s\n",oldline);
      printf("+ %s\n",newline);
    }
  }
  fclose(old);
  fclose(current);
  
}
  
    
      
		      
int main (int argc ,char *argv[]){
  if(argc < 2){
    printf("commands:\n");
    printf(" myvcs init <repo>\n");
    printf(" myvcs add <file>\n");
    printf(" myvcs commit <message>\n");
    printf(" myvcs status\n");
    printf(" myvcs log\n");
    printf(" myvcs checkout <commit_hash>\n");
    printf(" myvcs diff <file_name>\n");
    
    return 1;
  }
  if(strcmp(argv[1],"init")==0){
    init_repo(argv[2]);
  }
  else if(strcmp(argv[1],"add")==0 && argc == 3){
    add_file(argv[2]);
  }
  else if(strcmp(argv[1],"commit")==0 && argc == 3){
    commit(argv[2]);
  }
  else if(strcmp(argv[1],"status")==0){
    status();
  }
  else if(strcmp(argv[1],"log")==0){
    log_history();
  }
  else if(strcmp(argv[1],"checkout")==0){
    checkout(argv[2]);
  }
  else if(strcmp(argv[1],"diff")==0){
    diff(argv[2]);
  }
  else {
    printf("Invalid command.\n");
  }
  
  return 0;
}

  
    
		    


