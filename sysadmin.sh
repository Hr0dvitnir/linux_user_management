#! /bin/bash

function main(){
    PS3="Enter an operation's number [1-11]: "
    actions=("Add user" "Check user" "Edit user" "Lock user" "Backup user's files" "Delete user" "Create group" "Check group" "Edit group" "Delete group" "Exit")
    
    select action in "${actions[@]}"; do 
        case $REPLY in
                1)      
                        Add_user
                        ;;
                2)      
                        Check_user
                        ;;
                3)
                        Edit_user
                        ;;
                4)             
                        Lock_user
                        ;;
                5)
                        Backup_files
                        ;;
                6)
                        Delete_user
                        ;;
                7)
                        Create_group
                        ;;
                8)
                        Check_group
                        ;;
                9)
                        Edit_group
                        ;;
                10)
                        Delete_group
                        ;;
                11)		
			clear
                        exit
                        ;;
                *)
                        echo "Invalid input!"
                        ;;
            esac
    done
}


function Add_user(){ 
        while [[ true ]]; do
                read -p "Enter username: " username
                if id "$username" &>/dev/null; then
                        echo "User already exist."
                elif [[ $username = "q" ]]; then 
                        main
                elif [[ -z "$username" ]]; then
                        Add_user
                else 
                        echo "Enter groups that the new user will belong to: [Enter to skip]"
                        read -a grps
                        useradd -m $username
                        echo -e "\n---> User $username added.\n"
                        passwd -q $username 
                        for i in ${grps[@]}
                        do
                            if  usermod -aG $i $username &>/dev/null; then
                                        echo -e "\n---> $username added to $i\n"
                            else
                                        echo -e "Group $i doesn't exist.\n"
                            fi
                        done                          
                fi
        done
        echo -e "\n---> $username added.\n"
        Add_user
}


function Edit_user(){ 
    while [[ true ]]; do
        read -p "Enter username: " edit_name

        if id "$edit_name" &>/dev/null; then
            cat /etc/passwd | grep ^$edit_name| awk -F: '{print "\n1) Name:", $1,"\n2) Password: ", $2,"\n3) UID:", $3,"\n4) GID:", $4,"\n5) Info:", $5,"\n6) Home:", $6,"\n7) Shell:", $7}'
            groups $edit_name | awk -F: '{print "8) Groups:",$2}'
            passwd -Sa | grep ^$edit_name | awk '{print "9) Password info:\nMinimum age:", $4, "\nMaximum age:", $5, "\nWarning perriod:", $6, "\nInactivity period:", $7, "\n"}'
            locked=$( passwd -Sa | grep ^$edit_name | awk '{print $2}')
            if [[ $locked = "L" ]]; then
                    echo -e "User locked."
                    echo -e "Change password to unlock.\n"
            elif [[ $locked = "NP" ]]; then 
                    echo -e "No password set.\n"
            else 
                    echo -e "User not locked.\n"
            fi
        elif [[ $edit_name -eq "q" ]]; then
            main
        elif [[ -z "$edit_name" ]]; then
            Edit_user
        else
            echo -e "User not found.\n"
            Edit_user
        fi


        read -p "Enter what you want to change: " edit_opt
        case $edit_opt in
        1) 
                read -p "Enter new username: " new_name
                usermod -l $new_name $edit_name
                usermod -d /home/$new_name -m $new_name
                groupmod -n $new_name $edit_name 
                echo -e "\n---> Username changed.\n"
                Edit_user 
                ;;
        2)      
                passwd $edit_name
                Edit_user
                ;;

        3)          
                read -p "Enter the UID: " uid
                if usermod -u $uid $edit_name &>/dev/null; then
                	echo -e "\n---> UID changed.\n"
                else
                	echo -e "Invalid UID."      
                fi
                Edit_user
                ;;

        4)              
                read -p "Enter the GID: (Make sure that the group exists) " gid
                if  usermod -g $gid $edit_name &>/dev/null; then
                    echo -e "\n ---> GID chnaged.\n"
                else
                    echo -e "Invalid GID.\n"
                fi               
                Edit_user
                ;;
                

        5)
                read -p "Enter new comments: " comment
                if  usermod -c $comment $edit_name &>/dev/null; then
                        echo -e "\n ---> Comments added.\n"
                elif [[ $comment = "q" ]]; then
                        Edit_user
                else
                        echo -e "Invalid comment.\n"
                fi
                Edit_user
                ;;


        6) 
                read -p "Enter new home: " new_home
                usermod -m -d $new_home
                echo -e "\n ---> ${edit_name}'s new home is $new_home.\n"
                Edit_user
                ;;

        7)
                read -p "Enter new shell: " new_shell
                usermod -s $new_shell $edit_name
                echo -e "\n ---> ${edit_name}'s new shell is $new_shell\n"
                Edit_user
                ;;

        8)      
                read -p "Remove user from group or add user to group: [1/2] " opt_grp
                if [[ $opt_grp = 1 ]]; then
                        read -p "Enter group: " grp
                        if deluser $edit_name $grp &>/dev/null; then
                        	echo -e "\n ---> $edit_name removed from $grp\n"
                        	Edit_user
                        else
                        	echo "Invalid group."
                        fi
                        
                        
                elif [[ $opt_grp = 2 ]]; then
                        read -p "Enter group name to add: " grp
                        if  usermod -aG $grp $edit_name &>/dev/null; then
                                echo -e "\n ---> $edit_name added to $grp\n"
                        else 
                                echo -e "Group $grp doesn't esxit.\n"
                        fi
                        Edit_user
                else                
                        echo -e "Invalid input.\n"
                        Edit_user
                fi
                ;;

        9) 
                echo "Changing password info"
                echo -e "Leave empty to keep the same values.\n"
                read -p "Enter the number of inactive days: " inactive_days
                if [[ -z "$inactive_days" ]]; then
                        echo "Value kept as it is."
                else 
                         passwd -i $inactive_days $edit_name &>/dev/null
                fi

                read -p "Enter the minimum number of days between password changes: (0 to allow password change at anytime)" min_days
                if [[ -z "$min_days" ]]; then
                        echo "Value kept as it is."
                else
                         passwd -n $min_days $edit_name &>/dev/null
                fi

                read -p "Enter the maximum number of days a password remains valid: (-1 to remove checking)" max_days
                if [[ -z "$max_days" ]]; then
                    echo "Value kept as it is."
                else
                     passwd -x $max_days $edit_name &>/dev/null
                fi
            
                read -p "Set warning period: " warning_P
                if [[ -z "$warning_P" ]]; then
                    echo "Value kept as it is."
                else
                     passwd -w $warning_P $edit_name &>/dev/null
                fi
                echo -e "\n ---> Password info changed.\n"
                Edit_user
                ;;
        q)
		Edit_user
		;;
        *)
                echo "Invalid input."
                Edit_user
                ;;
        esac
	done
                        
}

function Lock_user(){
        while [[ true ]]; do
                read -p "Enter the username to lock his password: " user_lock  
                if id $user_lock &>/dev/null; then
                        passwd -l $user_lock &>/dev/null
                        echo -e "\n---> $user_lock locked"
                        echo -e "\n---> Set a new password to unlock.\n"
                elif [[ $user_lock = "q" ]]; then
                        main        
                else
                        echo -e "$user_lock not found.\n"       
                fi
                Lock_user
        done
}

function Delete_user(){
        while [[ true ]]; do
                read -p "Enter username: " del_name
                if id "$del_name" &>/dev/null; then
                        read -p "Are you sure you want to delete the user and all their files? [y/n]: " check
                        if [[ $check = "y" ]] || [[ $check = "Y" ]]; then
                                 userdel -rf $del_name &>/dev/null
                                echo -e "\n---> User $del_name deleted.\n"
                        else
                                main
                        fi
                        Delete_user
                elif [[ $del_name = "q" ]]; then
                        main
                else
                        echo -e "User not found.\n"
                        Delete_group
                fi
        done
}

function Create_group(){
        while [[ true ]]; do 
                read -p "Enter group name: " group
                if [[ $group = "q" ]]; then
                        main
                else
                        if  groupadd $group &>/dev/null; then
                        	echo -e "\n---> $group created.\n"
                        	echo "Enter users that will belong to $group: [Enter to skip]"
                        	read -a usrs
                        	for i in ${usrs[@]}
                        	do
                            	if  usermod -aG $group $i &>/dev/null; then
                                        echo -e "\n---> $i added to $group\n"
                            	else
                                        echo -e "\n---> User $i doesn't exist.\n"
                            	fi
                        	done
                        	Create_group
                        else
                                echo -e "Group already exist\n"
                                Create_group
                        fi
                fi
        done
}


function Backup_files(){
        while [[ true ]]; do
                read -p "Enter username to backup his files: " backup_name
                if id "$backup_name" &>/dev/null; then
                        read -p "Enter destination: " dest                    
                        Backup_files="/home/$backup_name"
                        b_date=$(date +%d-%m-%y)
                        arch_name="$backup_name-$b_date.tgz"
                        if  tar -czf $dest/$arch_name $Backup_files &>/dev/null; then
                            echo -e "\n---> Backup finished." 
                            echo -e "\n---> $arch_name saved in $dest\n"
                            Backup_files
                        else
                            echo -e "Invalid destination.\n"
                            Backup_files
                        fi
                elif [[ $backup_name = "q" ]]; then
                        main
                else
                        echo -e "User not found.\n"
                        Backup_files
                fi
        done
}

function Check_user(){
       
        while [[ true ]]; do
                read -p "Enter user: " name_check
                if id "$name_check" &>/dev/null; then
                        cat /etc/passwd | grep ^$name_check | awk -F: '{print "\nName:", $1,"\nUID:", $3,"\nGID:", $4,"\nInfo:", $5,"\nHome:", $6,"\nShell:", $7}'
                        groups $name_check | awk -F: '{print "Groups:",$2}'
                        lock=$( passwd -Sa | grep -w ^$name_check | awk '{print $2}')
                        if [[ $lock = "L" ]]; then
                                echo -e "\nUser locked.\n"
                        elif [[ $lock = "NP" ]]; then 
                                echo -e "\nNo password set.\n"
                        else 
                                echo -e "\nUser not locked.\n"
                        fi
                        passwd -Sa | grep ^$name_check | awk '{print "Last password change:", $3, "\nMinimum age:", $4, "\nMaximum age:", $5, "\nWarning perriod:", $6, "\nInactivity period:", $7, "\n"}'
                        logs=$(last $name_check | head -n -2 | awk '{print $7, $4, $6, $5}' | head)
                        if [[ -n "$logs" ]]; then
                                echo -e "\nLogs: \n"
                                echo "$logs"
                                read -p "More logs?[y/n]: " more_logs
		                        if  [[ $more_logs = "y" || $more_logs = "Y" ]]; then
		                        	last $name_check | head -n -2 | awk '{print $7, $4, $6, $5}'
		                        fi
                        fi
                        processes=$(ps -aux | grep ^$name_check | tail | awk '{print "Proccess:", $11, "at", $9,"PID:", $2}')
                        echo "$processes"
                        if [[ $processes ]]; then
                                read -p "More processes?[y/n] " more
                                if [[ $more = "y" ]] || [[ $more = "Y" ]]; then 
                                        ps -aux | grep ^$name_check | awk '{print "Proccess:", $11, "at", $9,"PID", $2}'
                                else
                                        Check_user
                                fi
                        fi
                        Check_user
                elif [[ $name_check = "q" ]]; then
                        main
                elif [[ -z "$name_check" ]]; then
                	Check_user
                else
                    echo -e "User not found.\n"
                    Check_user
                fi
        done
}

function Check_group(){      
        read -p "Enter group name: " check_group_name
        if [[ $check_group_name = "q" ]]; then
                main
        elif [[ -z "$check_group_name" ]]; then
        	Check_group
        else
            chk_grp=$(cat /etc/group | grep -w ^$check_group_name | awk -F: '{print "\n1) Name:", $1,"\n2) GID:", $3,"\n3) Users in "$1":", $4,"\n"}')
            if [[ -z "$chk_grp" ]]; then
                    echo "Invalid group."
                    Check_group
            else
                    echo "$chk_grp"             
            fi
        fi        
}

function Edit_group(){ 
        Check_group
        read -p "Enter what you want to change: " check_group_name_opt
        case $check_group_name_opt in
        1)
                read -p "Enter new group name: " grp_name
                if  groupmod -n $grp_name $check_group_name &>/dev/null; then
                        echo -e "\n---> Group name changed.\n"
                        Edit_group
                else
                        echo -e "Name not valid.\n"
                        Edit_group
                fi
                ;;
                        
        2)
                read -p "Enter new GID: " new_gid
                if  groupmod -g $new_gid $check_group_name &>/dev/null; then
                        echo -e "\n---> Group GID changed.\n"
                        Edit_group
                else
                        echo -e "GID not valid.\n"
                        Edit_group
                fi
                ;;

        3)
                read -p "Remove or add user? [1/2]: " opt
                if [[ $opt = 1 ]]; then
                        read -p "Enter user to remove: " rm_user
                        if deluser $rm_user $check_group_name &>/dev/null; then
                        	echo -e "\n---> $rm_user deleted from $check_group_name.\n"
                        	Edit_group
                        else
                        	echo -e "Invalid user."
                        	Edit_group
                        fi
                elif [[ $opt = 2 ]]; then
                        echo "Enter users to add: "
                        read -a add_usr_grp
                        for i in ${add_usr_grp[@]}
                        do
                                if  usermod -aG $check_group_name $i &>/dev/null; then
                                echo -e "\n---> $i added to $check_group_name.\n"
                        else
                                echo -e "User $i doesn't exist.\n"
                        fi
                        done
                        Edit_group
                else
                        echo -e "Invalid input.\n"
                        Edit_group
                fi
                ;;

        q)
                main
                ;;

        *)
                echo -e "Invalid input.\n"
                Edit_group
                ;;
        esac

                        
                
        
}

function Delete_group(){
        read -p "Enter group to delete: " del_grp
        if  groupdel $del_grp &>/dev/null; then
            echo -e "\n---> Group $del_grp deleted.\n"
        elif [[ $del_grp = "q" ]]; then
            main
        elif [[ -z "$del_grp" ]]; then
        	Delete_group
        else
            echo -e "Invalid group name.\n"
            Delete_group
        fi
}


if [[ $(whoami) != root  ]]; then
    echo "Root access needed!!!"
    exit 
else
        clear
       
        echo "#######################################################################"
        echo -e "\t\t\t     F.3.N.R.I.R\n"
        echo -e "\t\t\tSystem Administration"
        echo -e "#######################################################################\n"

        echo -e "q to exit entries.\n"
        main
fi