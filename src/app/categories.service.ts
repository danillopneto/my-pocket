import { Injectable } from '@angular/core';
import { AngularFirestore } from '@angular/fire/firestore';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { Category } from './models/category.model';
import { throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class CategoriesService {
  private categoriesUrl: string = 'https://localhost:44305/api/v1/category';
  
  constructor(private firestore: AngularFirestore, private http: HttpClient) {
  }

  getCollectionReference() {
    return this.firestore.collection('danillopneto').doc("userSettings").collection<Category>("categories");
  }

  getCategory(id: string) {
    return this.getCollectionReference().doc(id).valueChanges();
  }

  getCategories() {
    return this.getCollectionReference().snapshotChanges();
  }

  removeCategory(id: string) {
    return this.getCollectionReference().doc(id).delete();
  }

  saveCategory(category: Category) {
    if (category.id == null || category.id == '') {
      const uuidv1 = require('uuid/v1');
      category.id = uuidv1();
    }

    return this.getCollectionReference().doc(category.id).set({... category});
  }
}
