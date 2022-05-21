#!/bin/bash

function main(){
        actions="Add_user Check_user Edit_user Lock_user Backup_user_files Delete_user Create_group Check_group Edit_group Delete_group Exit"
        
        select action in $actions; do 
                if [[ $action = "Add_user" ]]; then
                        Add_user
                elif [[ $action = "Check_user" ]]; then
                        Check_user
                elif [[ $action = "Edit_user" ]]; then
                        Edit_user
				elif [[ $action = "Lock_user" ]]; then
						Lock_user 
                elif [[ $action = "Backup_user_files" ]]; then
                        Backup_files
                elif [[ $action = "Delete_user" ]]; then
                        Delete_user
                elif [[ $action = "Create_group" ]]; then
                        Create_group
                elif [[ $action = "Check_group" ]]; then
                		Check_group
                elif [[ $action = "Edit_group" ]]; then
                		Edit_group
                elif [[ $action = "Delete_group" ]]; then
                		Delete_group
                elif [[ $action = "Exit" ]]; then
                        exit
                else 
                        echo -e "Invalid input.\n"	
                fi

        done
}


function Add_user(){ 
        c=0
        while [ $c -eq 0 ]; do
                read -p "Enter username: " username
                if id "$username" &>/dev/null; then
                        echo "User already exist."
                elif [[ $username = "q" ]]; then
                        main
                elif [[ -z "$username" ]]; then
                	Add_user
                else 
                        echo "Enter groups that the new user will belong to: "
                        read -a grps
                        sudo useradd -m $username
                        sudo passwd -q $username 
                    	for i in ${grps[@]}
                    	do
                            if sudo usermod -aG $i $username &>/dev/null; then
                            	echo "$username added to $i"
                            else
                            	echo -e "Group $i doesn't exist.\n"
                            fi
                    	done
                    	c=1
                                            
                fi
        done
        echo -e "\n$username added.\n"
        Add_user

}


function Edit_user(){ 
        echo -e "\n\tEditing user"
        c=0
        while [ $c -eq 0 ]; do

                read -p "Enter username: " edit_name

                if id "$edit_name" &>/dev/null; then
                    cat /etc/passwd | grep ^$edit_name| awk -F: '{print "\n1) Name:", $1,"\n2) Password: ", $2,"\n3) UID:", $3,"\n4) GID:", $4,"\n5) Info:", $5,"\n6) Home:", $6,"\n7) Shell:", $7}'
                    groups $edit_name | awk -F: '{print "8) Groups:",$2}'
                    sudo passwd -Sa | grep ^$edit_name | awk '{print "9) Password info:\nMinimum age:", $4, "\nMaximum age:", $5, "\nWarning perriod:", $6, "\nInactivity period:", $7, "\n"}'
                    locked=$(sudo passwd -Sa | grep ^$edit_name | awk '{print $2}')
                    if [[ $locked = "L" ]]; then
                            echo -e "User locked."
                            echo -e "Change password to unlock.\n"
                    elif [[ $locked = "NP" ]]; then 
                            echo -e "No password set.\n"
                    else 
                            echo -e "User not locked.\n"

                    fi
                    c=1
                elif [[ $edit_name -eq "q" ]]; then
                    main
                elif [[ -z "$edit_name" ]]; then
                	Edit_user
                else
                    echo -e "User not found.\n"
                fi
        done

		read -p "Enter what you want to change: " edit_opt
		case $edit_opt in
		1) 
			read -p "Enter new username: " new_name
		  	sudo usermod -l $new_name $edit_name
			sudo usermod -d /home/$new_name -m $new_name
			sudo groupmod -n $new_name $edit_name 
			echo -e "Username changed.\n"
			Edit_user 
			;;
        2)	
            sudo passwd $edit_name
			Edit_user
            ;;

		3)
            echo "Leave empty to keep original value."
			read -p "Enter the UID: " uid
            if [[ -z "$uid" ]]; then
                    echo ""
            else 
                    sudo usermod -u $uid $edit_name
                    echo -e "UID changed.\n"
            fi
			Edit_user
			;;

		4)
			echo "Leave empty to keep original value."
			read -p "Enter the GID: (Make sure that the group exists) " gid
			if [[ -z "$gid" ]]; then
                echo ""
            else
            	if sudo usermod -g $gid $edit_name &>/dev/null; then
            		echo -e "GID chnaged.\n"
            	else
            		echo -e "Invalid GID.\n"
            	fi
            fi
            Edit_user
            ;;
			

		5)
            read -p "Enter new comments: " comment
            if sudo usermod -c $comment $edit_name &>/dev/null; then
            	echo -e "Comments added.\n"
            elif [[ $comment = "q" ]]; then
            	Edit_user
            else
            	echo -e "Invalid comment.\n"
            fi
			Edit_user
            ;;


        6) 
            read -p "Enter new home: " new_home
            sudo usermod -m -d $new_home
            echo -e "${edit_name}'s new home is $new_home.\n"
			Edit_user
            ;;

        7)
            read -p "Enter new shell: " new_shell
            sudo usermod -s $new_shell $edit_name
            echo -e "${edit_name}'s new shell is $new_shell\n"
			Edit_user
            ;;

        8)      
			read -p "Remove user from group or add user to group: [1/2] " opt_grp
            if [[ $opt_grp = 1 ]]; then
                 	read -p "Enter group: " grp
                    sudo deluser $edit_name $grp &>/dev/null
                    echo -e "$edit_name removed from $grp\n"
					Edit_user
            elif [[ $opt_grp = 2 ]]; then
                    read -p "Enter group name to add: " grp
                    if sudo usermod -aG $grp $edit_name &>/dev/null; then
                    	echo -e "$edit_name added to $grp\n"
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
                    sudo passwd -i $inactive_days $edit_name &>/dev/null
            fi
            read -p "Enter the minimum number of days between password changes: (0 to allow password change at anytime)" min_days
            if [[ -z "$min_days" ]]; then
                    echo "Value kept as it is."
            else
                    sudo passwd -n $min_days $edit_name &>/dev/null
            fi
            read -p "Enter the maximum number of days a password remains valid: (-1 to ramove checking)" max_days
            if [[ -z "$max_days" ]]; then
                    echo "Value kept as it is."
            else
                    sudo passwd -x $max_days $edit_name &>/dev/null
            fi
            
            read -p "Set warning period: " warning_P
            if [[ -z "$warning_P" ]]; then
                    echo "Value kept as it is."
            else
                    sudo passwd -w $warning_P $edit_name &>/dev/null
            fi
            echo -e "Password info changed.\n"
			Edit_user
            ;;
        *)
			echo "Invalid input."
			Edit_user
			;;
        esac
			
}

function Lock_user(){
		c=0
	    while [ $c -eq 0 ]; do
			read -p "Enter the username to lock his password: " user_lock
			
			if id $user_lock &>/dev/null; then
				sudo passwd -l $user_lock &>/dev/null
			        echo "$user_lock locked"
		            echo -e "Set a new password to unlock.\n"
            elif [[ $user_lock = "q" ]]; then
                    main	
			else
				echo -e "$user_lock not found.\n"	
			fi
			c=1
		done
		Lock_user
}

function Delete_user(){
        c=0
        while [ $c -eq 0 ]; do
                read -p "Enter username: " del_name
                if id "$del_name" &>/dev/null; then
                        read -p "Are you sure you want to delete the user and all their files? [y/n]: " check
                        if [[ $check = "y" ]] || [[ $check = "Y" ]]; then
                                sudo userdel -rf $del_name &>/dev/null
                                echo -e "User deleted.\n"
                        else
                                main
                        fi
                        c=1
                elif [[ $del_name = "q" ]]; then
                        main
                else
                        echo -e "User not found.\n"
                fi
        done
        Delete_user


}

function Create_group(){
        c=0
        while [ $c -eq 0 ]; do 
                read -p "Enter group name: " group
                if [[ $group = "q" ]]; then
                    main
                else
                    if sudo groupadd $group &>/dev/null; then
                        echo -e "$group created.\n"
                        c=1
                    else
                    	echo -e "Group already exist\n"
                    fi
                fi
        done
        Create_group
}


function Backup_files(){
        c=0
        while [ $c -eq 0 ]; do
                read -p "Enter username to backup his files: " backup_name
                if id "$backup_name" &>/dev/null; then
                        read -p "Enter destination: " dest
                        Backup_files="/home/$backup_name"
                        b_date=$(date +%d-%m-%y)
                        arch_name="$backup_name-$b_date.tgz"
                        if sudo tar -czf $dest/$arch_name $Backup_files &>/dev/null; then
                        	echo -e "Backup finished." 
                        	echo -e "$arch_name saved in $dest\n"
                        	c=1
                        else
                        	echo -e "Invalid destination.\n"
                        fi
                elif [[ $backup_name = "q" ]]; then
                        main
                else
                        echo -e "User not found.\n"
                fi
        done


}

function Check_user(){
        c=0
        while [ $c -eq 0 ]; do
                read -p "Enter user: " name_check
                if id "$name_check" &>/dev/null; then
                        cat /etc/passwd | grep ^$name_check | awk -F: '{print "\nName:", $1,"\nUID:", $3,"\nGID:", $4,"\nInfo:", $5,"\nHome:", $6,"\nShell:", $7}'
                        groups $name_check | awk -F: '{print "Groups:",$2}'
                        logs=$(last $name_check | head -n -2 | awk '{print $7, $4, $6, $5}')
                        if [[ -n "$logs" ]]; then
                        	echo -e "\nLogs: \n"
                        	echo "$logs"
                        else
                        	echo ""
                        fi 
                        lock=$(sudo passwd -Sa | grep -w ^$name_check | awk '{print $2}')
                        if [[ $lock = "L" ]]; then
                                echo -e "\nUser locked.\n"
                        elif [[ $lock = "NP" ]]; then 
                                echo -e "\nNo password set.\n"
                        else 
                                echo -e "\nUser not locked.\n"

                        fi
                        sudo passwd -Sa | grep ^$name_check | awk '{print "Last password change:", $3, "\nMinimum age:", $4, "\nMaximum age:", $5, "\nWarning perriod:", $6, "\nInactivity period:", $7, "\n"}'
                        processes=$(ps -aux | grep ^$name_check | tail | awk '{print "Proccess:", $11, "at", $9,"PID:", $2}')
                        echo "$processes"
                        if [[ $processes ]]; then
                                read -p "More processes?[y/n] " more
                                if [[ $more = "y" ]] || [[ $more = "Y" ]]; then 
                                        ps -aux | grep ^$name_check | awk '{print "Proccess:", $11, "at", $9,"PID", $2}'
                                else
                                        main
                                fi
                        fi
                        c=1
                elif [[ $name_check = "q" ]]; then
                	main
                else
                    echo -e "User not found.\n"
                fi
        done
        Check_user

}

function Check_group(){
	c=0
	while [[ $c -eq 0 ]]; do
		read -p "Enter group name: " check_group_name
		if [[ $check_group_name = "q" ]]; then
			main
		fi
		chk_grp=$(cat /etc/group | grep -w ^$check_group_name | awk -F: '{print "\n1) Name:", $1,"\n2) GID:", $3,"\n3) Users in "$1":", $4,"\n"}')
		if [[ -z "$chk_grp" ]]; then
			echo "Group dosn't exist."
		else
			echo "$chk_grp"
			c=1
		fi
	done
	 
}

function Edit_group(){ 

		Check_group
		read -p "Enter what you want to change: " check_group_name_opt
		case $check_group_name_opt in
		1)
			read -p "Enter new group name: " grp_name
			if sudo groupmod -n $grp_name $check_group_name &>/dev/null; then
				echo -e "Group name changed.\n"
				Edit_group
			else
				echo -e "Name not valid.\n"
				Edit_group
			fi
			;;
				
		2)
			read -p "Enter new GID: " new_gid
			if sudo groupmod -g $new_gid $check_group_name &>/dev/null; then
				echo -e "Group GID changed.\n"
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
				sudo deluser $rm_user $check_group_name &>/dev/null
				echo -e "$rm_user deleted from $check_group_name.\n"
				Edit_group
			elif [[ $opt = 2 ]]; then
				echo "Enter users to add: "
				read -a add_usr_grp
				for i in ${add_usr_grp[@]}
                    do
                            if sudo usermod -aG $check_group_name $i &>/dev/null; then
                            	echo -e "$i added to $check_group_name.\n"
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
	if sudo groupdel $del_grp &>/dev/null; then
		echo -e "Group deleted.\n"
	elif [[ $del_grp = "q" ]]; then
		main
	else
		echo -e "Invalid group name.\n"
		Delete_group
	fi
}
echo "========================================================"
echo -e "\t\tUser management script"
echo -e "\t\tF.3.N.R.I.R"
echo -e "========================================================\n"

echo -e "q to exit entries.\nChoose an option: [1-11]"
main
