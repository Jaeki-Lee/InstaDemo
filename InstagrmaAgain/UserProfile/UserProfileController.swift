//
//  UserProfileControllerCollectionViewController.swift
//  InstagrmaAgain
//
//  Created by Jae Ki Lee on 12/4/17.
//  Copyright © 2017 Jae Ki LeeJae. All rights reserved.
//

import UIKit
import Firebase

class UserProfileController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UserProfileHeaderDelegate {
    
    var isGridView = true
    
    func didChangeToGridView() {
        isGridView = true
        collectionView?.reloadData()
    }
    
    func didChnageToListView() {
        isGridView = false
        collectionView?.reloadData()
    }
    
    let cellId = "cellId"
    
    //for getting user info from searchingViewController
    var userId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.backgroundColor = .white
        
        //Fetch User
        fetchUser()
        
        //forSuppleme ntaryView 보조 뷰로 프레임워크 되어인는듯 함
        //Header Cell
        collectionView?.register(UserProfileHeader.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "headerId")
        
        //Cell
        collectionView?.register(UserProfilePhotoCell.self, forCellWithReuseIdentifier: cellId)
        
        //Cell for TableCell, 이곳에서는 이곳에서의 패치 포스트 사용하므로, 로그인한 유저에 대한 포스트만 가져올 수 있다.
        collectionView?.register(HomePostCell.self, forCellWithReuseIdentifier: "homePostCellId")
        
        //Logout gear button
        setupLogOutButton()
        
//        //Fetch data
//        fetchOrderedPosts()
        
    }
    
    var user : User?
    
    fileprivate func fetchUser(){
        //2. userId 가 있으면 쓰고 아니면(프로파일뷰로 들어온 거라면)최근 유저정보를 쓰는
        //if userId == nil, then uid = Auth.auth().currentUser?.uid
        let uid = userId ?? (Auth.auth().currentUser?.uid ?? "")
        
        //"fetchUserWithUID" 의 user 가 데이터를 User로 옮겨준다.
        Database.fetchUserWithUID(uid: uid) {(user) in
            self.user = user
            self.navigationItem.title = self.user?.username
            
            self.collectionView?.reloadData()
            
            self.fetchOrderedPosts()
        }
    }
    
    /*
     4. controller 에서 외부파일과 연결되는 변수를 선언하고 그 선언된 변수에 추가 파일을 추가시켜 업데이트 시킨다.
     */
    var posts = [Post]()
    /*
     1. DB에서 데이터를 가져온다
     */
    fileprivate func fetchOrderedPosts(){
        guard let uid = user?.uid else {return}
        
        let ref = Database.database().reference().child("posts").child(uid)
        
        //childeAdded 는 그전에 데이터베이스에 데이터를 올릴때 포스트폴더 - 유저유아이디 - 사진마다랜덤유아이디 넣었기 때문에 다시 뺄때도 childAdded 를 넣어줘야함.
        ref.queryOrdered(byChild: "creationDate").observe(.childAdded, with: {(snapshot) in
            guard let dictionary = snapshot.value as? [String : Any] else {return}
            // 같은 class 에 변수가 존재하더라도 함수 밖에 있는 변수를 사용하려면 변수를 함수 안에서 다시 패스 받아서 사용하여야 한다.
            guard let user = self.user else {return}
            
            /*
             2. 다른 파일에 그 데이터를 저장할 공간을 만들어 놓고
             3. FetchPosts 에서 외부파일에 데이터를 저장한다
             */
            
            let post = Post(user: user, dictionary: dictionary)
            
            self.posts.insert(post, at: 0)
            
            self.collectionView?.reloadData()
            
        }) { (err) in
            print("Failed to fetch ordered posts", err)
        }
    }
    
    
    fileprivate func setupLogOutButton() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"), style: .plain, target: self, action: #selector(handleLogOut))
        
    }
    
    @objc func handleLogOut() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { (_) in
            
            do {
                try Auth.auth().signOut()
                
                let loginController = LoginController()
                let navController = UINavigationController(rootViewController: loginController)
                self.present(navController, animated: true, completion: nil)
                
            } catch let signOutErr {
                print("Failed to sign Out", signOutErr)
            }
            
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    //Cell count
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
        
    }
    //Cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if isGridView{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! UserProfilePhotoCell
            
            //        cell.photoImageView
            cell.post = posts[indexPath.item]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "homePostCellId", for: indexPath) as! HomePostCell
            cell.post = posts[indexPath.item]
            return cell
        }
        
    }
    
    //cell 세로 나누는 줄 크기
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    //cell 가로 나누는 줄 크기
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    //Cell size
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isGridView{
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {
            var height : CGFloat = 40 + 8 + 8 // userName and Profilepicture
            height += view.frame.width //photo
            height += 50 // icons
            height += 60 // Username and caption and postTime
            height += 20 // userProfileImage view extending
            
            return CGSize(width: view.frame.width, height: height)
        }
        
    }
    
    //Header
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    
        //*3. 헤더뷰를 이곳에 가져와서 보여준다.
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "headerId", for: indexPath) as! UserProfileHeader
        
        header.user = self.user
        
      //header delegate 에 이 메서드를 넣는다
        header.delegate = self
        
        //not correct
        //header.addSubView(UIImageView())
        
        return header
        
    }

    
}





