import { Expense } from './../models/expense.model';
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';
import { UtilityService } from '../services/utility.service';
import { Category } from '../models/category.model';
import { CategoriesService } from '../services/categories.service';
import { ExpensesService } from '../services/expense.service';
import { PaymentMethod } from '../enumerators/enum.payment.method';

@Component({
  selector: 'app-expense',
  templateUrl: './expense.component.html',
  styleUrls: ['./expense.component.scss']
})
export class ExpenseComponent implements OnInit {

  PaymentMethod = PaymentMethod;
  form: FormGroup;
  submitted: boolean = false;
  success: boolean = false;
  categories: Category[];
  expenses: Expense[];

  constructor(
    private formBuilder: FormBuilder,
    private util: UtilityService,
    private expensesService: ExpensesService,
    private categoriesService: CategoriesService) {
    this.form = this.createFormGroup();
  }

  ngOnInit() {
  }

  ngAfterViewInit() {
    this.getCategories();
    this.getExpenses();
  }

  createFormGroup() {
    return this.formBuilder.group({
      idCategory: new FormControl('', [Validators.required]),
      date: new FormControl(),
      description: new FormControl(),
      id: new FormControl(),
      paymentMethod: new FormControl(),
      value: new FormControl()
    });
  }

  getCategories() {
    this.util.showLoading();

    this.categoriesService.getAll('description').subscribe(data => {
      this.categories = data;
      this.util.hideLoading();
    }, err => {
      this.util.hideLoading();
    });
  }

  getExpenses() {
    this.expensesService.getAll().subscribe(data => {
      this.expenses = data;
      this.util.hideLoading();
    }, err => {
      this.util.hideLoading();
    });
  }

  onSubmit() {
    this.submitted = true;

    if (this.form.invalid) {
      return;
    }

    this.saveExpense();
    this.success = true;
  }

  saveExpense() {
    debugger;
    this.util.showLoading();

    var idCategory = this.form.value.idCategory;
    var newExpense = new Expense(
      this.form.value.id,
      this.util.getDayFromDate(this.form.value.date.toJSON()),
      this.util.getMonthFromDate(this.form.value.date.toJSON()),
      this.util.getYearFromDate(this.form.value.date.toJSON()),
      idCategory,
      this.form.value.description,
      this.form.value.value,
      PaymentMethod.Credit);

    newExpense.category = this.categoriesService.getCollectionReference().doc(idCategory).ref;

    this.expensesService
      .save(newExpense)
      .catch(() => {
        this.util.hideLoading();
      })
      .then(() => {
        this.form = this.createFormGroup();
        this.getCategories();
        this.getExpenses();
      })
      .finally(() => {
        this.util.hideLoading();
      });;
  }
}
