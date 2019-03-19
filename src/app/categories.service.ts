import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpErrorResponse } from '@angular/common/http';
import { Category } from './models/category.model';
import { throwError } from 'rxjs';
import { catchError, retry } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class CategoriesService {
  private categoriesUrl: string = 'https://localhost:44305/api/v1/category';
  
  constructor(private http: HttpClient) {
  }

  getCategories() {
    return this.http.get<Category[]>(this.categoriesUrl);
  }

  removeCategory(id: string) {
    return this.http.delete(this.categoriesUrl + '/' + id);
  }

  saveCategory(category: Category) {
    if (category.id == null || category.id == '') {
      return this.http.post(this.categoriesUrl, category);
    } else {
      return this.http.put(this.categoriesUrl + '/' + category.id, category);
    }
  }
}
